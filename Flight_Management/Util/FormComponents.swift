import SwiftUI


struct FormFieldLabel: ViewModifier {
    
    func body(content: Content) -> some View {
        content
            .font(.callout)
            .font(.system(size: 15))
            .foregroundColor(Color(.systemGray))
            .padding(.leading, 4)
    }
}

extension Text {
    func formFieldLabel() -> some View {
        modifier(FormFieldLabel())
    }
}
