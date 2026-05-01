import Foundation
import SwiftTerm
import Combine

@MainActor
class QuickAccessEngineManager: ObservableObject {
    @Published var isProcessRunning = false
    @Published var hasUnreadMessages = false
    
    @Published var availableModels: [String] = []
    @Published var selectedModel: String = "gemma4:e4b"
    
    
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
    
    
    func startProcess() {
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
        
        var args = ["--continue"]
        if !selectedModel.isEmpty {
            args.insert(contentsOf: ["--model", selectedModel], at: 0)
        }
        
        terminalView.startProcess(executable: executable, args: args, environment: envArray, execName: nil)
        isProcessRunning = true
    }
    
    func stopProcess() {
        if isProcessRunning {
            terminalView.terminate()
            isProcessRunning = false
        }
    }
    
    func restartProcess() {
        if isProcessRunning {
            stopProcess()
            // Clear the terminal screen for a clean start
            terminalView.terminal.feed(text: "\u{001b}[2J\u{001b}[H") 
            
            // Slightly longer delay to ensure SwiftTerm has cleaned up the old process
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                self.startProcess()
            }
        } else {
            startProcess()
        }
    }
}
