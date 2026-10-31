import UIKit

/// Design tokens: every colour, font size and spacing value lives here, once.
/// Screens never hard-code `#0B6E4F` or `17pt` — they say `StoreColor.primary`, `StoreFont.body`.
/// Change the brand here and the whole app follows (including dark mode, below).
enum StoreColor {
    static let primary       = dynamic(light: 0x1D4ED8, dark: 0x60A5FA)   // campus blue
    static let primarySoft   = dynamic(light: 0xDBEAFE, dark: 0x172554)
    static let accent        = dynamic(light: 0xF59E0B, dark: 0xFBBF24)   // amber
    static let ink           = dynamic(light: 0x0F172A, dark: 0xF1F5F9)
    static let textSecondary = dynamic(light: 0x475569, dark: 0xA7B3C4)
    static let muted         = dynamic(light: 0x94A3B8, dark: 0x64748B)
    static let line          = dynamic(light: 0xE2E8F0, dark: 0x273449)
    static let background    = dynamic(light: 0xF8FAFC, dark: 0x0B1120)
    static let surface       = dynamic(light: 0xFFFFFF, dark: 0x111A2E)
    static let danger        = dynamic(light: 0xDC2626, dark: 0xF87171)
    static let dangerSoft    = dynamic(light: 0xFEE2E2, dark: 0x3B1414)
    static let success       = dynamic(light: 0x16A34A, dark: 0x4ADE80)
    static let successSoft   = dynamic(light: 0xDCFCE7, dark: 0x0F2E1C)
    static let onPrimary     = UIColor.white

    /// UIKit re-evaluates this closure whenever light/dark mode changes.
    private static func dynamic(light: Int, dark: Int) -> UIColor {
        UIColor { $0.userInterfaceStyle == .dark ? UIColor(hex: dark) : UIColor(hex: light) }
    }
}

/// `UIFontMetrics` makes each style grow with the user's Dynamic Type setting (accessibility).
enum StoreFont {
    static let display  = scaled(32, .bold, .largeTitle)
    static let title    = scaled(20, .bold, .title3)
    static let headline = scaled(17, .semibold, .headline)
    static let body     = scaled(15, .regular, .body)
    static let bodyBold = scaled(15, .semibold, .body)
    static let caption  = scaled(12, .regular, .caption1)
    static let button   = scaled(16, .semibold, .body)

    private static func scaled(_ size: CGFloat, _ weight: UIFont.Weight, _ style: UIFont.TextStyle) -> UIFont {
        UIFontMetrics(forTextStyle: style).scaledFont(for: .systemFont(ofSize: size, weight: weight))
    }
}

enum StoreSpacing {
    static let tight: CGFloat = 8
    static let item: CGFloat = 12
    static let control: CGFloat = 16
    static let page: CGFloat = 20
    static let section: CGFloat = 24
}

enum StoreRadius {
    static let control: CGFloat = 12
    static let card: CGFloat = 16
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1) {
        self.init(red: CGFloat((hex >> 16) & 0xFF) / 255,
                  green: CGFloat((hex >> 8) & 0xFF) / 255,
                  blue: CGFloat(hex & 0xFF) / 255,
                  alpha: alpha)
    }
}
