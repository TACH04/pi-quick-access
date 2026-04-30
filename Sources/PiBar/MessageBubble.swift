import SwiftUI

struct MessageBubble: View {
    let message: Message
    
    var body: some View {
        HStack {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(12)
                    .background(Theme.userGradient)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text(getMarkdown(message.content))
                    .padding(12)
                    .background(Theme.assistantBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Theme.assistantBorder, lineWidth: 1)
                    )
                    .foregroundColor(.primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 4)
    }
    
    private func getMarkdown(_ text: String) -> AttributedString {
        // Normalize newlines to ensure they are rendered as line breaks in SwiftUI's Markdown parser
        // LLMs often use single newlines which Markdown standard treats as spaces.
        let processedText = text.replacingOccurrences(of: "\n", with: "  \n")
        
        do {
            var attributedString = try AttributedString(markdown: processedText, options: .init(interpretedSyntax: .full))
            attributedString.font = .system(.body, design: .default)
            return attributedString
        } catch {
            return AttributedString(text)
        }
    }
}
