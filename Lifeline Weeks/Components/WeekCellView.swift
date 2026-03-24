import SwiftUI

struct WeekCellView: View, Equatable {
    let state:       WeekState
    var isMilestone: Bool       = false
    var theme:       AppTheme   = .dark
    var gridStyle:   GridStyle  = .minimal
    /// Overrides the size from gridStyle — set by LifeGridView's responsive layout.
    var cellSize:    CGFloat    = 0   // 0 = use gridStyle.cellSize

    static func == (lhs: WeekCellView, rhs: WeekCellView) -> Bool {
        lhs.state       == rhs.state       &&
        lhs.isMilestone == rhs.isMilestone &&
        lhs.theme       == rhs.theme       &&
        lhs.gridStyle   == rhs.gridStyle   &&
        Int(lhs.resolvedSize * 10) == Int(rhs.resolvedSize * 10)  // 0.1pt precision
    }

    @State private var glowing = false

    private var resolvedSize: CGFloat { cellSize > 0 ? cellSize : gridStyle.cellSize }

    var body: some View {
        let size   = resolvedSize
        // Scale corner radius proportionally to the cell size
        let radius = gridStyle.cornerRadius * (size / gridStyle.cellSize)

        RoundedRectangle(cornerRadius: radius, style: .continuous)
            .fill(fillColor)
            .overlay(borderOverlay(radius: radius))
            .frame(width: size, height: size)
            .modifier(PulseModifier(active: state == .current, glowing: glowing))
            .weekGlow(color: state == .current ? theme.weekCurrent : .clear)
            .onAppear { if state == .current { glowing = true } }
    }

    // MARK: - Overlays

    @ViewBuilder
    private func borderOverlay(radius: CGFloat) -> some View {
        if state == .current {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(theme.weekCurrent, lineWidth: 1.5)
        } else if isMilestone {
            RoundedRectangle(cornerRadius: radius, style: .continuous)
                .strokeBorder(theme.accentGold.opacity(0.8), lineWidth: 1.2)
        }
    }

    // MARK: - Fill color

    private var fillColor: Color {
        switch state {
        case .past:    return theme.weekPast
        case .current: return theme.weekCurrent
        case .future:  return theme.weekFuture
        }
    }
}

// MARK: - Pulse modifier

private struct PulseModifier: ViewModifier {
    let active:  Bool
    let glowing: Bool

    func body(content: Content) -> some View {
        if active {
            content
                .scaleEffect(glowing ? 1.08 : 1.0)
                .animation(.easeInOut(duration: 1.4).repeatForever(autoreverses: true), value: glowing)
        } else {
            content
        }
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.appBg.ignoresSafeArea()
        HStack(spacing: 6) {
            WeekCellView(state: .past)
            WeekCellView(state: .current)
            WeekCellView(state: .future)
            WeekCellView(state: .past, isMilestone: true)
        }
        .padding()
    }
    .preferredColorScheme(.dark)
}
