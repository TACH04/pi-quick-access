import SwiftUI
import SwiftTerm

struct ChatView: View {
    @ObservedObject var processManager: QuickAccessEngineManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Image(systemName: "terminal.fill")
                    .foregroundColor(.accentColor)
                Text("Pi Agent CLI")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Button(action: {
                    processManager.restartProcess()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .help("Restart Pi")
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                        .help("Quit")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Terminal
            TerminalViewWrapper(manager: processManager)
                .background(Color.black)
                .cornerRadius(8)
                .padding(8)
                .background(Color(NSColor.windowBackgroundColor))
        }
        .frame(minWidth: 500, minHeight: 400)
    }
}

#Preview {
    ChatView(processManager: QuickAccessEngineManager())
}
