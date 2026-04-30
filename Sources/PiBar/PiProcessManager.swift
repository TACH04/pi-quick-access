import Foundation

@MainActor
class PiProcessManager: ObservableObject {
    @Published var isStreaming = false
    @Published var currentResponse = ""
    @Published var finishedResponse: String?
    
    var selectedModel: String = ""
    private var process: Process?
    
    func send(query: String) async {
        self.isStreaming = true
        self.currentResponse = ""
        self.finishedResponse = nil
        
        let process = Process()
        self.process = process
        process.executableURL = URL(fileURLWithPath: "/usr/local/bin/pi")
        
        var args = [
            "-p",
            "--no-session",
            "--mode", "json",
            "--provider", "ollama",
            query
        ]
        
        if !selectedModel.isEmpty {
            args.insert(contentsOf: ["--model", selectedModel], at: args.count - 1)
        }
        
        process.arguments = args
        
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe() // Ignore stderr for now
        
        do {
            try process.run()
            
            Task {
                do {
                    for try await line in pipe.fileHandleForReading.bytes.lines {
                        await parseJSONLine(line)
                    }
                    
                    process.waitUntilExit()
                    
                    await handleCompletion()
                } catch {
                    await handleError(error)
                }
            }
        } catch {
            await handleError(error)
        }
    }
    
    func stop() {
        process?.terminate()
        self.isStreaming = false
        if !self.currentResponse.isEmpty {
            self.finishedResponse = self.currentResponse
            self.currentResponse = ""
        }
    }
    
    private func handleCompletion() {
        self.isStreaming = false
        if !self.currentResponse.isEmpty {
            self.finishedResponse = self.currentResponse
            self.currentResponse = ""
        }
    }
    
    private func handleError(_ error: Error) {
        self.currentResponse = "Error: \(error.localizedDescription)"
        self.isStreaming = false
        self.finishedResponse = self.currentResponse
        self.currentResponse = ""
    }
    
    private func parseJSONLine(_ line: String) {
        guard let data = line.data(using: .utf8) else { return }
        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let type = json["type"] as? String {
                
                if type == "message_update",
                   let event = json["assistantMessageEvent"] as? [String: Any],
                   let eventType = event["type"] as? String,
                   eventType == "text_delta",
                   let delta = event["delta"] as? String {
                    DispatchQueue.main.async {
                        self.currentResponse += delta
                    }
                } else if type == "tool_execution_start",
                          let toolName = json["tool_name"] as? String {
                    DispatchQueue.main.async {
                        self.currentResponse += "\n*Using tool: \(toolName)...*\n"
                    }
                } else if type == "turn_end",
                          let message = json["message"] as? [String: Any],
                          let content = message["content"] as? [[String: Any]] {
                    // Fallback for non-streamed responses
                    var fullText = ""
                    for item in content {
                        if item["type"] as? String == "text",
                           let text = item["text"] as? String {
                            fullText += text
                        }
                    }
                    DispatchQueue.main.async {
                        if self.currentResponse.isEmpty && !fullText.isEmpty {
                            self.currentResponse = fullText
                        }
                    }
                }
            }
        } catch {
            // Not JSON or parse error, ignore
        }
    }
}
