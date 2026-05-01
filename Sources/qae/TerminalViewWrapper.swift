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

    @MainActor
    class Coordinator: NSObject, LocalProcessTerminalViewDelegate {
        var parent: TerminalViewWrapper

        init(_ parent: TerminalViewWrapper) {
            self.parent = parent
        }

        nonisolated func processTerminated(source: TerminalView, exitCode: Int32?) {
            Task { @MainActor in
                let manager = self.parent.manager
                let pid = (source as? LocalProcessTerminalView)?.process.shellPid ?? 0
                manager.isProcessRunning = false
                if pid > 0 {
                    manager.markProcessExited(pid: pid)
                }
                print("Pi process terminated with exit code \(exitCode ?? -1)")
            }
        }

        nonisolated func sizeChanged(source: LocalProcessTerminalView, newCols: Int, newRows: Int) {
        }
        
        nonisolated func setTerminalTitle(source: LocalProcessTerminalView, title: String) {
        }
        
        nonisolated func hostCurrentDirectoryUpdate(source: TerminalView, directory: String?) {
        }
    }
}

extension LocalProcessTerminalView {
    func configureTerminal(delegate: LocalProcessTerminalViewDelegate) {
        self.processDelegate = delegate
    }
}
