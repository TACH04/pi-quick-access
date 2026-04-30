import SwiftUI

struct InputBar: View {
    @Binding var text: String
    var isStreaming: Bool
    var onSend: () -> Void
    var onStop: () -> Void
    
    var body: some View {
        HStack {
            TextField("Ask pi anything...", text: $text)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Color.white.opacity(0.1))
                .cornerRadius(16)
                .onSubmit {
                    if !isStreaming && !text.isEmpty {
                        onSend()
                    }
                }
            
            Button(action: {
                if isStreaming {
                    onStop()
                } else if !text.isEmpty {
                    onSend()
                }
            }) {
                Image(systemName: isStreaming ? "stop.circle.fill" : "arrow.up.circle.fill")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(isStreaming ? .red : (text.isEmpty ? .gray : .accentColor))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
    }
}
