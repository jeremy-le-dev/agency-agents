import SwiftUI

enum AppColors {
    static let background = Color(hex: "F7F8FA")
    static let cardBackground = Color.white
    static let primaryText = Color(hex: "1A1D26")
    static let secondaryText = Color(hex: "6B7280")
    static let accent = Color(hex: "2563EB")
    static let positive = Color(hex: "10B981")
    static let negative = Color(hex: "EF4444")
    static let divider = Color(hex: "E5E7EB")
    static let shadow = Color.black.opacity(0.06)
}

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }

    static func institution(_ type: InstitutionType) -> Color {
        Color(hex: type.brandColorHex)
    }
}

enum AppTypography {
    static func largeTitle() -> Font { .system(size: 36, weight: .bold, design: .rounded) }
    static func title() -> Font { .system(size: 22, weight: .semibold, design: .rounded) }
    static func headline() -> Font { .system(size: 17, weight: .semibold) }
    static func body() -> Font { .system(size: 15, weight: .regular) }
    static func caption() -> Font { .system(size: 13, weight: .regular) }
    static func amount() -> Font { .system(size: 20, weight: .semibold, design: .rounded) }
    static func smallAmount() -> Font { .system(size: 16, weight: .medium, design: .rounded) }
}

struct CardStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(AppColors.cardBackground)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .shadow(color: AppColors.shadow, radius: 8, x: 0, y: 2)
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardStyle())
    }
}
