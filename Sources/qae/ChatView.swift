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
                
                if !processManager.availableModels.isEmpty {
                    Picker("", selection: $processManager.selectedModel) {
                        ForEach(processManager.availableModels, id: \.self) { model in
                            Text(model).tag(model)
                        }
                    }
                    .labelsHidden()
                    .frame(maxWidth: 200)
                    .onChange(of: processManager.selectedModel) { _, _ in
                        processManager.restartProcess()
                    }
                }
                
                Button(action: {
                    processManager.restartProcess()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .help("Restart Pi")
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
                
                Button(action: {
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .foregroundColor(.red)
                        .help("Quit")
                }
                .buttonStyle(.plain)
                .padding(.leading, 8)
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
        .onAppear {
            processManager.fetchAvailableModels()
        }
    }
}

#Preview {
    ChatView(processManager: QuickAccessEngineManager())
}
