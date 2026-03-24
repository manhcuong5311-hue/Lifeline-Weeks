import SwiftUI

// ─────────────────────────────────────────────
// MARK: - App Store config
// ─────────────────────────────────────────────
enum AppConfig {
    /// Numeric App Store ID — update if the app is ever re-listed.
    static let appStoreID = "6761049878"

    /// Opens the App Store page for this app.
    static let appStoreURL = URL(string: "https://apps.apple.com/app/id\(appStoreID)")!

    /// Opens the App Store review sheet directly.
    static let reviewURL   = URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")!
}

// ─────────────────────────────────────────────
// MARK: - Spacing & Radius tokens
// ─────────────────────────────────────────────
enum DS {
    enum Spacing {
        static let xs:  CGFloat = 4
        static let s:   CGFloat = 8
        static let m:   CGFloat = 12
        static let l:   CGFloat = 16
        static let xl:  CGFloat = 24
        static let xxl: CGFloat = 32
    }
    enum Radius {
        static let s:  CGFloat = 8
        static let m:  CGFloat = 12
        static let l:  CGFloat = 16
        static let xl: CGFloat = 20
        static let pill: CGFloat = 100
    }
}

// ─────────────────────────────────────────────
// MARK: - Color palette  (always-dark)
// ─────────────────────────────────────────────
extension Color {

    // Backgrounds
    static let appBg          = Color(red: 0.051, green: 0.051, blue: 0.059)  // #0D0D0F
    static let appBgElevated  = Color(red: 0.102, green: 0.102, blue: 0.114)  // #1A1A1D
    static let appSurface     = Color(white: 1.0).opacity(0.055)               // glass card
    static let appDivider     = Color(white: 1.0).opacity(0.07)

    // Text
    static let textPrimary    = Color(white: 0.94)                             // #F0F0F0
    static let textSecondary  = Color(white: 0.94).opacity(0.55)
    static let textTertiary   = Color(white: 0.94).opacity(0.32)

    // Week cell states
    static let weekPast       = Color(white: 0.70)                             // soft gray-white
    static let weekCurrent    = Color(red: 0.47, green: 0.65, blue: 1.00)      // soft blue
    static let weekFuture     = Color(white: 0.70).opacity(0.11)

    // Accent
    static let accentBlue     = Color(red: 0.47, green: 0.65, blue: 1.00)
    static let accentPurple   = Color(red: 0.72, green: 0.52, blue: 1.00)
    static let accentGold     = Color(red: 1.00, green: 0.80, blue: 0.40)      // milestone
}

// ─────────────────────────────────────────────
// MARK: - Gradients
// ─────────────────────────────────────────────
extension LinearGradient {
    /// App-wide dark background
    static let appBackground = LinearGradient(
        colors: [Color.appBg, Color.appBgElevated],
        startPoint: .top, endPoint: .bottom
    )
    /// Blue → purple accent used on numbers & CTAs
    static let accent = LinearGradient(
        colors: [Color.accentBlue, Color.accentPurple],
        startPoint: .leading, endPoint: .trailing
    )
    static let accentDiagonal = LinearGradient(
        colors: [Color.accentBlue, Color.accentPurple],
        startPoint: .topLeading, endPoint: .bottomTrailing
    )
}

// ─────────────────────────────────────────────
// MARK: - Typography scale
// ─────────────────────────────────────────────
extension Font {
    /// 52 pt — hero percentage
    static let lifeHero:    Font = .system(size: 52, weight: .bold,     design: .rounded)
    /// 28 pt — section headlines
    static let lifeTitle:   Font = .system(size: 28, weight: .bold,     design: .rounded)
    /// 22 pt — stat numbers
    static let lifeStat:    Font = .system(size: 22, weight: .semibold, design: .rounded)
    /// 17 pt — subheading / secondary labels
    static let lifeSubhead: Font = .system(size: 17, weight: .medium,   design: .rounded)
    /// 16 pt — body copy
    static let lifeBody:    Font = .system(size: 16, weight: .regular,  design: .rounded)
    /// 13 pt — captions / hints
    static let lifeCaption: Font = .system(size: 13, weight: .regular,  design: .rounded)
    /// 11 pt — micro labels, uppercase tracking
    static let lifeLabel:   Font = .system(size: 11, weight: .medium,   design: .rounded)
}

// ─────────────────────────────────────────────
// MARK: - Reusable view modifiers
// ─────────────────────────────────────────────

/// Glass card: semi-transparent surface + hairline border
struct GlassCard: ViewModifier {
    var radius: CGFloat = DS.Radius.l
    func body(content: Content) -> some View {
        content
            .background(Color.appSurface)
            .clipShape(RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Color.appDivider, lineWidth: 1)
            )
    }
}

extension View {
    func glassCard(radius: CGFloat = DS.Radius.l) -> some View {
        modifier(GlassCard(radius: radius))
    }

    /// Dual-layer glow shadow — used on the current-week cell.
    func weekGlow(color: Color = .weekCurrent) -> some View {
        self
            .shadow(color: color.opacity(0.75), radius: 4,  x: 0, y: 0)
            .shadow(color: color.opacity(0.30), radius: 10, x: 0, y: 0)
    }

    // Legacy alias kept for compatibility
    func cardStyle(radius: CGFloat = DS.Radius.l) -> some View { glassCard(radius: radius) }
}
