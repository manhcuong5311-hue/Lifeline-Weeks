import SwiftUI
import Combine

// MARK: - Theme Style

enum AppThemeStyle: String, CaseIterable, Identifiable {
    case dark      = "Dark"
    case light     = "Light"
    case system    = "System"
    case midnight  = "Midnight"
    case beige     = "Beige"
    case amoled    = "AMOLED"

    var id: String { rawValue }

    var isPremium: Bool {
        switch self { case .midnight, .beige, .amoled: return true; default: return false }
    }

    var symbolName: String {
        switch self {
        case .dark:     return "moon.fill"
        case .light:    return "sun.max.fill"
        case .system:   return "circle.lefthalf.filled"
        case .midnight: return "sparkles"
        case .beige:    return "leaf.fill"
        case .amoled:   return "bolt.fill"
        }
    }
}

// MARK: - Grid Style

enum GridStyle: String, CaseIterable, Identifiable {
    case minimal  = "Minimal"
    case contrast = "Contrast"
    case bold     = "Bold"

    var id: String { rawValue }

    var cellSize:     CGFloat { self == .bold ? 12 : 10 }
    var cellGap:      CGFloat { self == .bold ? 2.0 : 2.5 }
    var cornerRadius: CGFloat { self == .bold ? 4 : 3 }

    var pastOpacity:   Double { self == .contrast ? 0.90 : (self == .minimal ? 0.70 : 0.82) }
    var futureOpacity: Double { self == .contrast ? 0.07 : 0.11 }
}

// MARK: - App Theme

struct AppTheme: Equatable {
    let style: AppThemeStyle

    let background:         Color
    let backgroundElevated: Color
    let surface:            Color
    let divider:            Color

    let textPrimary:   Color
    let textSecondary: Color
    let textTertiary:  Color

    let weekPast:    Color
    let weekCurrent: Color
    let weekFuture:  Color

    let accentBlue:   Color
    let accentPurple: Color
    let accentGold:   Color

    // Computed gradients
    var accentGradient: LinearGradient {
        LinearGradient(colors: [accentBlue, accentPurple],
                       startPoint: .leading, endPoint: .trailing)
    }
    var accentDiagonal: LinearGradient {
        LinearGradient(colors: [accentBlue, accentPurple],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [background, backgroundElevated],
                       startPoint: .top, endPoint: .bottom)
    }
    // Preferred color scheme to apply to the host view
    var colorScheme: ColorScheme? {
        switch style {
        case .light, .beige: return .light
        case .system:        return nil
        default:             return .dark
        }
    }

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool { lhs.style == rhs.style }
}

// MARK: - Theme catalogue

extension AppTheme {

    static let dark = AppTheme(
        style: .dark,
        background:         Color(red: 0.078, green: 0.078, blue: 0.090),  // brighter base
        backgroundElevated: Color(red: 0.130, green: 0.130, blue: 0.148),  // clearer cards
        surface:            Color(white: 1.0).opacity(0.09),               // more visible surfaces
        divider:            Color(white: 1.0).opacity(0.12),               // clearer dividers
        textPrimary:        Color(white: 0.97),                            // near-white
        textSecondary:      Color(white: 0.97).opacity(0.65),             // easier to read
        textTertiary:       Color(white: 0.97).opacity(0.42),             // less muddy
        weekPast:           Color(white: 0.82),                            // brighter lived weeks
        weekCurrent:        Color(red: 0.47, green: 0.65, blue: 1.00),
        weekFuture:         Color(white: 0.82).opacity(0.13),             // slightly more visible
        accentBlue:         Color(red: 0.47, green: 0.65, blue: 1.00),
        accentPurple:       Color(red: 0.72, green: 0.52, blue: 1.00),
        accentGold:         Color(red: 1.00, green: 0.80, blue: 0.40)
    )

    static let light = AppTheme(
        style: .light,
        background:         Color(red: 0.961, green: 0.961, blue: 0.969),
        backgroundElevated: Color.white,
        surface:            Color.white.opacity(0.7),
        divider:            Color.black.opacity(0.08),
        textPrimary:        Color(red: 0.067, green: 0.067, blue: 0.075),
        textSecondary:      Color(red: 0.067, green: 0.067, blue: 0.075).opacity(0.55),
        textTertiary:       Color(red: 0.067, green: 0.067, blue: 0.075).opacity(0.32),
        weekPast:           Color(red: 0.28, green: 0.28, blue: 0.33),
        weekCurrent:        Color(red: 0.25, green: 0.50, blue: 0.95),
        weekFuture:         Color(red: 0.28, green: 0.28, blue: 0.33).opacity(0.12),
        accentBlue:         Color(red: 0.25, green: 0.50, blue: 0.95),
        accentPurple:       Color(red: 0.55, green: 0.35, blue: 0.95),
        accentGold:         Color(red: 0.85, green: 0.60, blue: 0.10)
    )

    static let midnight = AppTheme(
        style: .midnight,
        background:         Color(red: 0.020, green: 0.035, blue: 0.098),
        backgroundElevated: Color(red: 0.040, green: 0.065, blue: 0.150),
        surface:            Color(white: 1.0).opacity(0.055),
        divider:            Color(white: 1.0).opacity(0.08),
        textPrimary:        Color(red: 0.88, green: 0.91, blue: 1.00),
        textSecondary:      Color(red: 0.88, green: 0.91, blue: 1.00).opacity(0.55),
        textTertiary:       Color(red: 0.88, green: 0.91, blue: 1.00).opacity(0.32),
        weekPast:           Color(red: 0.45, green: 0.55, blue: 0.80),
        weekCurrent:        Color(red: 0.35, green: 0.75, blue: 1.00),
        weekFuture:         Color(red: 0.45, green: 0.55, blue: 0.80).opacity(0.12),
        accentBlue:         Color(red: 0.35, green: 0.75, blue: 1.00),
        accentPurple:       Color(red: 0.55, green: 0.50, blue: 1.00),
        accentGold:         Color(red: 1.00, green: 0.80, blue: 0.40)
    )

    static let beige = AppTheme(
        style: .beige,
        background:         Color(red: 0.957, green: 0.945, blue: 0.929),
        backgroundElevated: Color(red: 0.980, green: 0.973, blue: 0.962),
        surface:            Color(red: 0.95, green: 0.93, blue: 0.91).opacity(0.6),
        divider:            Color(red: 0.35, green: 0.28, blue: 0.20).opacity(0.12),
        textPrimary:        Color(red: 0.180, green: 0.155, blue: 0.125),
        textSecondary:      Color(red: 0.180, green: 0.155, blue: 0.125).opacity(0.55),
        textTertiary:       Color(red: 0.180, green: 0.155, blue: 0.125).opacity(0.32),
        weekPast:           Color(red: 0.40, green: 0.32, blue: 0.24),
        weekCurrent:        Color(red: 0.72, green: 0.40, blue: 0.18),
        weekFuture:         Color(red: 0.40, green: 0.32, blue: 0.24).opacity(0.14),
        accentBlue:         Color(red: 0.72, green: 0.40, blue: 0.18),
        accentPurple:       Color(red: 0.55, green: 0.25, blue: 0.15),
        accentGold:         Color(red: 0.82, green: 0.58, blue: 0.18)
    )

    static let amoled = AppTheme(
        style: .amoled,
        background:         .black,
        backgroundElevated: Color(white: 0.04),
        surface:            Color(white: 1.0).opacity(0.04),
        divider:            Color(white: 1.0).opacity(0.055),
        textPrimary:        .white,
        textSecondary:      Color.white.opacity(0.55),
        textTertiary:       Color.white.opacity(0.30),
        weekPast:           Color(white: 0.75),
        weekCurrent:        Color(red: 0.47, green: 0.65, blue: 1.00),
        weekFuture:         Color(white: 0.75).opacity(0.08),
        accentBlue:         Color(red: 0.47, green: 0.65, blue: 1.00),
        accentPurple:       Color(red: 0.72, green: 0.52, blue: 1.00),
        accentGold:         Color(red: 1.00, green: 0.80, blue: 0.40)
    )

    static func make(for style: AppThemeStyle) -> AppTheme {
        switch style {
        case .dark:     return .dark
        case .light:    return .light
        case .midnight: return .midnight
        case .beige:    return .beige
        case .amoled:   return .amoled
        case .system:   return .dark   // overridden at runtime
        }
    }
}

// MARK: - ThemeManager

@MainActor
final class ThemeManager: ObservableObject {

    @AppStorage("app.themeStyle") private var storedStyle: String = AppThemeStyle.light.rawValue
    @AppStorage("app.gridStyle")  private var storedGrid:  String = GridStyle.minimal.rawValue

    @Published private(set) var current: AppTheme = .light

    private var systemColorScheme: ColorScheme = .dark

    init() { current = resolveTheme() }

    // MARK: - Public

    var themeStyle: AppThemeStyle { AppThemeStyle(rawValue: storedStyle) ?? .light }

    var gridStyle: GridStyle {
        get { GridStyle(rawValue: storedGrid) ?? .minimal }
        set {
            HapticFeedback.light()
            withAnimation(.easeInOut(duration: 0.25)) {
                storedGrid = newValue.rawValue
                objectWillChange.send()
            }
        }
    }

    func setTheme(_ style: AppThemeStyle) {
        HapticFeedback.light()
        withAnimation(.easeInOut(duration: 0.4)) {
            storedStyle = style.rawValue
            current = resolveTheme()
        }
    }

    func updateSystemScheme(_ scheme: ColorScheme) {
        guard systemColorScheme != scheme else { return }
        systemColorScheme = scheme
        guard themeStyle == .system else { return }
        withAnimation(.easeInOut(duration: 0.4)) {
            current = resolveTheme()
        }
    }

    // MARK: - Private

    private func resolveTheme() -> AppTheme {
        themeStyle == .system
            ? (systemColorScheme == .dark ? .dark : .light)
            : AppTheme.make(for: themeStyle)
    }
}
