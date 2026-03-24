import SwiftUI

struct LifeGridView: View {
    let weeks:            [LifeWeek]
    var milestoneIndices: Set<Int> = []
    var birthDate:        Date     = Date()

    @EnvironmentObject private var themeManager: ThemeManager

    @State private var selectedWeek:   LifeWeek?
    @State private var availableWidth: CGFloat = 0

    private let labelWidth: CGFloat = 26

    private var totalYears: Int { max(1, (weeks.count + 51) / 52) }

    // MARK: - Responsive metrics
    // Solve for gap and cellSize that fill availableWidth exactly,
    // while preserving each GridStyle's native cellSize/gap ratio.
    private func metrics() -> (cellSize: CGFloat, gap: CGFloat) {
        let style = themeManager.gridStyle
        guard availableWidth > 0 else { return (style.cellSize, style.cellGap) }

        // Row layout: labelWidth + gap + 52*cellSize + 51*gap = availableWidth
        //   → labelWidth + 52*gap = available gap "budget"
        // Keep ratio r = cellSize / gap constant
        let r   = style.cellSize / max(style.cellGap, 0.1)
        // availableWidth = labelWidth + 52*(r+1)*gap
        let gap = max(0.5, (availableWidth - labelWidth) / (52.0 * (r + 1.0)))
        let cs  = r * gap
        return (cs, gap)
    }

    var body: some View {
        let (cellSize, gap) = metrics()
        LazyVStack(spacing: gap) {
            ForEach(0..<totalYears, id: \.self) { year in
                yearRow(year, gap: gap, cellSize: cellSize)
            }
        }
        .padding(.horizontal, DS.Spacing.m)
        .padding(.vertical, DS.Spacing.s)
        // Measure the view's own width after padding is applied
        .background(
            GeometryReader { geo in
                Color.clear
                    .onAppear        { availableWidth = geo.size.width }
                    .onChange(of: geo.size.width) { _, w in availableWidth = w }
            }
        )
        .sheet(item: $selectedWeek) { week in
            WeekDetailView(week: week, birthDate: birthDate)
        }
    }

    // MARK: - Year row

    @ViewBuilder
    private func yearRow(_ year: Int, gap: CGFloat, cellSize: CGFloat) -> some View {
        let start = year * 52
        let end   = min(start + 52, weeks.count)
        if start < weeks.count {
            let slice     = Array(weeks[start..<end])
            let theme     = themeManager.current
            let gridStyle = themeManager.gridStyle
            HStack(spacing: gap) {
                ageLabel(year)
                    .frame(width: labelWidth, alignment: .trailing)

                HStack(spacing: gap) {
                    ForEach(slice) { week in
                        Button {
                            HapticFeedback.medium()
                            selectedWeek = week
                        } label: {
                            WeekCellView(
                                state:       week.state,
                                isMilestone: milestoneIndices.contains(week.index),
                                theme:       theme,
                                gridStyle:   gridStyle,
                                cellSize:    cellSize
                            )
                            .equatable()
                        }
                        .buttonStyle(WeekPressStyle())
                        .id(week.id)
                    }

                    // Pad incomplete last year with transparent placeholders
                    if slice.count < 52 {
                        ForEach(0..<(52 - slice.count), id: \.self) { _ in
                            Color.clear.frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ageLabel(_ year: Int) -> some View {
        if year % 5 == 0 {
            Text("\(year)")
                .font(.system(size: 8, weight: .medium, design: .monospaced))
                .foregroundStyle(themeManager.current.textTertiary)
        } else {
            Color.clear
        }
    }
}

// MARK: - Press style

private struct WeekPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.82 : 1.0)
            .animation(.spring(response: 0.25, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

// MARK: - Preview

#Preview {
    let bd    = Calendar.current.date(byAdding: .year, value: -30, to: Date())!
    let weeks = LifeCalculator.generateWeeks(birthDate: bd, lifeExpectancyYears: 80)
    return ZStack {
        LinearGradient.appBackground.ignoresSafeArea()
        ScrollView {
            LifeGridView(weeks: weeks, birthDate: bd)
        }
    }
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}
