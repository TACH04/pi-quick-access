import Foundation
import SwiftTerm
import Combine

@MainActor
class QuickAccessEngineManager: ObservableObject {
    @Published var isProcessRunning = false
    @Published var hasUnreadMessages = false
    
    @Published var availableModels: [String] = []
    @Published var selectedModel: String = "gemma4:e4b"
    
    // Track all PIDs we've started to ensure we can kill them even if they become orphaned
    private var activePids = Set<pid_t>()
    private var pidsLock = NSLock()
    
    // Track the model currently being executed to ensure we stop the right one
    private var currentlyRunningModel: String?
    
    let terminalView: LocalProcessTerminalView
    
    init() {
        // Initialize terminal view with a default frame
        self.terminalView = LocalProcessTerminalView(frame: .zero)
        
        // Premium styling
        setupTerminalStyling()
    }
    
    private func setupTerminalStyling() {
        // SwiftTerm styling
        terminalView.terminal.softReset()
        
        // Helper to create colors from 0-255 values
        func c8(_ r: UInt16, _ g: UInt16, _ b: UInt16) -> Color {
            return Color(red: r * 257, green: g * 257, blue: b * 257)
        }
        
        // Create a basic 16-color palette based on standard terminal colors
        // but with improved contrast for output (7) and thinking (8)
        let palette: [Color] = [
            c8(0, 0, 0),       // 0: Black
            c8(194, 54, 33),   // 1: Red
            c8(37, 188, 36),   // 2: Green
            c8(173, 173, 39),  // 3: Yellow
            c8(73, 46, 225),   // 4: Blue
            c8(211, 56, 211),  // 5: Magenta
            c8(51, 187, 200),  // 6: Cyan
            c8(255, 255, 255), // 7: White (Main Output) - Pure White
            
            c8(100, 110, 120), // 8: Bright Black (Thinking) - Slate Grey
            c8(252, 57, 31),   // 9: Bright Red
            c8(49, 231, 34),   // 10: Bright Green
            c8(234, 236, 35),  // 11: Bright Yellow
            c8(88, 51, 255),   // 12: Bright Blue
            c8(249, 53, 248),  // 13: Bright Magenta
            c8(20, 240, 240),  // 14: Bright Cyan
            c8(233, 235, 235)  // 15: Bright White
        ]
        
        // Set explicit foreground and background colors for the terminal
        terminalView.terminal.foregroundColor = c8(255, 255, 255) // Pure White default
        terminalView.terminal.backgroundColor = c8(0, 0, 0)       // Pure Black default
        
        terminalView.terminal.installPalette(colors: palette)
        
        // Silence "Unknown OSC code: 133" (Shell Integration) messages
        terminalView.terminal.registerOscHandler(code: 133) { _ in }
    }
    
    func fetchAvailableModels() {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/pi")
        process.arguments = ["--list-models"]
        
        let pipe = Pipe()
        process.standardOutput = pipe
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let lines = output.components(separatedBy: .newlines)
                var models: [String] = []
                for line in lines {
                    if line.hasPrefix("ollama") {
                        let components = line.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
                        if components.count >= 2 {
                            models.append(components[1])
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.availableModels = models
                    if !models.contains(self.selectedModel) && !models.isEmpty {
                        self.selectedModel = models.first!
                    }
                }
            }
        } catch {
            print("Failed to fetch models: \(error)")
        }
    }
    
    
    func startProcess(isNewSession: Bool = false) {
        guard !isProcessRunning else { return }
        
        let executable = "/usr/local/bin/pi"
        
        // Construct environment with a robust PATH to find node and other tools
        var env = ProcessInfo.processInfo.environment
        let extraPaths = ["/usr/local/bin", "/opt/homebrew/bin", "/usr/bin", "/bin", "/usr/sbin", "/sbin"]
        let currentPath = env["PATH"] ?? ""
        let newPath = (extraPaths + [currentPath]).joined(separator: ":")
        env["PATH"] = newPath
        
        // Convert [String: String] to [String] as required by SwiftTerm (usually "KEY=VALUE" format)
        let envArray = env.map { "\($0.key)=\($0.value)" }
        
        var args: [String] = []
        if !isNewSession {
            args.append("--continue")
        }
        
        if !selectedModel.isEmpty {
            args.insert(contentsOf: ["--model", selectedModel], at: 0)
        }
        
        terminalView.startProcess(executable: executable, args: args, environment: envArray, execName: nil)
        
        currentlyRunningModel = selectedModel
        
        let pid = terminalView.process.shellPid
        if pid > 0 {
            pidsLock.lock()
            activePids.insert(pid)
            pidsLock.unlock()
        }
        
        isProcessRunning = true
    }
    
    func markProcessExited(pid: pid_t) {
        pidsLock.lock()
        activePids.remove(pid)
        pidsLock.unlock()
    }
    
    func stopProcess(isAppExiting: Bool = false) {
        // 1. Try to tell Ollama to unload the model that was actually running
        if let modelToStop = currentlyRunningModel {
            let stopProc = Process()
            stopProc.executableURL = URL(fileURLWithPath: "/usr/local/bin/ollama")
            stopProc.arguments = ["stop", modelToStop]
            try? stopProc.run()
        }

        // 2. Send Ctrl+C to the terminal
        terminalView.send(data: [0x03][...])
        
        pidsLock.lock()
        let pidsToKill = activePids
        pidsLock.unlock()
        
        // 3. Send SIGTERM to all known active processes (including orphans from previous model switches)
        for pid in pidsToKill {
            kill(-pid, SIGTERM)
            kill(pid, SIGTERM)
        }
        
        terminalView.terminate()
        
        if isAppExiting {
            // Synchronous aggressive cleanup on app exit
            Thread.sleep(forTimeInterval: 0.5)
            for pid in pidsToKill {
                if kill(pid, 0) == 0 {
                    kill(-pid, SIGKILL)
                    kill(pid, SIGKILL)
                }
            }
        } else {
            // Background cleanup for switching models
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                for pid in pidsToKill {
                    if kill(pid, 0) == 0 {
                        kill(-pid, SIGKILL)
                        kill(pid, SIGKILL)
                    }
                }
            }
        }
        
        isProcessRunning = false
    }
    
    func restartProcess(isNewSession: Bool = false) {
        if isProcessRunning {
            stopProcess()
            // Clear the terminal screen for a clean start
            terminalView.terminal.feed(text: "\u{001b}[2J\u{001b}[H") 
            
            // Longer delay to ensure SwiftTerm has cleaned up and Ollama has unloaded the model
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                self.startProcess(isNewSession: isNewSession)
            }
        } else {
            startProcess(isNewSession: isNewSession)
        }
    }
}
