import SwiftUI

enum FSColor {
    static let ink = Color(red: 10/255, green: 10/255, blue: 15/255)
    static let inkElevated = Color(red: 18/255, green: 18/255, blue: 26/255)
    static let card = Color(red: 24/255, green: 24/255, blue: 34/255)
    static let teal = Color(red: 20/255, green: 184/255, blue: 166/255)
    static let flame = Color(red: 249/255, green: 115/255, blue: 22/255)
    static let stroke = Color.white.opacity(0.08)
    static let textSecondary = Color.white.opacity(0.62)
}

struct FSBadge: View {
    let text: String
    var tint: Color = FSColor.teal
    var body: some View {
        Text(text)
            .font(.system(size: 12, weight: .semibold, design: .rounded))
            .foregroundStyle(tint)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tint.opacity(0.14), in: Capsule())
            .overlay(Capsule().stroke(tint.opacity(0.3), lineWidth: 1))
    }
}

struct FSCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12, content: { content })
            .padding(18)
            .background(FSColor.card, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(FSColor.stroke, lineWidth: 1)
            )
    }
}
