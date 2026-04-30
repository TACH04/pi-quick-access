import SwiftUI

struct ModelPicker: View {
    @Binding var selectedModel: String
    @State private var availableModels: [ModelInfo] = []
    
    var body: some View {
        Picker("Model", selection: $selectedModel) {
            ForEach(availableModels) { model in
                Text(model.name).tag(model.id)
            }
        }
        .pickerStyle(MenuPickerStyle())
        .onAppear(perform: loadModels)
    }
    
    func loadModels() {
        let fileURL = URL(fileURLWithPath: NSHomeDirectory() + "/.pi/agent/models.json")
        do {
            let data = try Data(contentsOf: fileURL)
            let modelsData = try JSONDecoder().decode(AvailableModels.self, from: data)
            if let ollamaProvider = modelsData.providers["ollama"] {
                self.availableModels = ollamaProvider.models
                if self.selectedModel.isEmpty && !self.availableModels.isEmpty {
                    self.selectedModel = self.availableModels[0].id
                }
            }
        } catch {
            print("Failed to load models: \(error)")
            self.availableModels = [ModelInfo(id: "gemma4:e4b", name: "Gemma 4 E4B")]
            if self.selectedModel.isEmpty {
                self.selectedModel = "gemma4:e4b"
            }
        }
    }
}
