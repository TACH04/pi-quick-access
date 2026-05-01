import SwiftUI
import AppKit
import SwiftTerm

struct TerminalViewWrapper: NSViewRepresentable {
    @ObservedObject var manager: QuickAccessEngineManager

    func makeNSView(context: Context) -> LocalProcessTerminalView {
        let view = manager.terminalView
        view.configureTerminal(delegate: context.coordinator)
        
        // Start the process if not already running
        if !manager.isProcessRunning {
            manager.startProcess()
        }
        
        return view
    }

    func updateNSView(_ nsView: LocalProcessTerminalView, context: Context) {
        // Handle updates if necessary
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var parent: TerminalViewWrapper

        init(_ parent: TerminalViewWrapper) {
            self.parent = parent
        }

        func processTerminated(source: TerminalView, exitCode: Int32?) {
            let manager = self.parent.manager
            
            Task { @MainActor in
                let pid = (source as? LocalProcessTerminalView)?.process.shellPid ?? 0
                manager.isProcessRunning = false
                if pid > 0 {
                    manager.markProcessExited(pid: pid)
                }
                print("Pi process terminated with exit code \(exitCode ?? -1)")
            }
        }

        func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
            // SwiftTerm handles this internally mostly
        }
        
        func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
            // Optional: update window title
        }
        
        func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        }
    }
}

extension LocalProcessTerminalView {
    func configureTerminal(delegate: LocalProcessTerminalViewDelegate) {
        self.processDelegate = delegate
    }
}
