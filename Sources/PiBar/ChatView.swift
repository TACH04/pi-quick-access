import SwiftUI

struct ChatView: View {
    @StateObject private var processManager = PiProcessManager()
    @State private var inputText: String = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("PiBar")
                    .font(.headline)
                Spacer()
                ModelPicker(selectedModel: $processManager.selectedModel)
                    .frame(width: 150)
            }
            .padding()
            .background(Color.black.opacity(0.2))
            
            // Chat Area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { message in
                            MessageBubble(message: message)
                                .id(message.id)
                        }
                        
                        if !processManager.currentResponse.isEmpty {
                            MessageBubble(message: Message(content: processManager.currentResponse, isUser: false))
                                .id("currentResponse")
                        }
                    }
                    .padding(.top)
                }
                .onChange(of: messages.count) { _ in
                    scrollToBottom(proxy: proxy)
                }
                .onChange(of: processManager.currentResponse) { _ in
                    scrollToBottom(proxy: proxy)
                }
            }
            
            // Input Area
            InputBar(text: $inputText, isStreaming: processManager.isStreaming, onSend: sendMessage, onStop: stopMessage)
        }
        .frame(width: 380, height: 520)
        // Glassmorphism background
        .background(VisualEffectView(material: .hudWindow, blendingMode: .behindWindow))
        .onReceive(processManager.$finishedResponse) { response in
            if let resp = response {
                messages.append(Message(content: resp, isUser: false))
            }
        }
    }
    
    func sendMessage() {
        let query = inputText
        inputText = ""
        messages.append(Message(content: query, isUser: true))
        Task {
            await processManager.send(query: query)
        }
    }
    
    func stopMessage() {
        processManager.stop()
    }
    
    func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation {
            if !processManager.currentResponse.isEmpty {
                proxy.scrollTo("currentResponse", anchor: .bottom)
            } else if let last = messages.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}

struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
