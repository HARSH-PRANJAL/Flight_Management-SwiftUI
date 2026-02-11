import SwiftUI

struct TextWithCopyView: View {
    
    let text: String
    
    @State private var justCopied = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            Text(text)
                .font(.body)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
                .multilineTextAlignment(.leading)
                .accessibilityLabel("Detail: \(text)")
            
            Image(systemName: justCopied ? "checkmark.circle.fill" : "doc.on.doc")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(justCopied ? Color(.systemGreen) : Color(.systemGray2))
                .frame(maxWidth: 15, maxHeight: 15)
                .accessibilityLabel("Copy to clipboard")
                .accessibilityHint("Double tap to copy the detail text")
                .accessibilityAddTraits(.isButton)
                .onTapGesture {
                    copyToClipboard()
                }
                .contentShape(Rectangle())
                .padding(4)
        }
        .padding(.bottom, 30)
        .overlay(alignment: .top) {
            if justCopied {
                Text("Copied!")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(.systemGray4))
                    .clipShape(.capsule)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .padding(.top, -20)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: justCopied)
    }
    
    private func copyToClipboard() {
        UIPasteboard.general.string = text
        
        withAnimation {
            justCopied = true
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            withAnimation {
                justCopied = false
            }
        }
    }
}
