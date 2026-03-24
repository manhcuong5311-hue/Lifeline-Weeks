import SwiftUI

// MARK: - Configuration

enum ShareLayout: String, CaseIterable, Identifiable {
    case poster   = "Poster"    // 9:16 story format
    case square   = "Square"    // 1:1 Instagram
    case minimal  = "Minimal"   // grid only, no stats

    var id: String { rawValue }

    var size: CGSize {
        switch self {
        case .poster:  return CGSize(width: 360, height: 640)
        case .square:  return CGSize(width: 390, height: 390)
        case .minimal: return CGSize(width: 360, height: 480)
        }
    }

    var exportScale: CGFloat { 3 }  // all layouts export at 3× → ≥1080 px
}

struct ShareConfig {
    var layout: ShareLayout = .poster
    var name:   String      = ""

    nonisolated init(layout: ShareLayout = .poster, name: String = "") {
        self.layout = layout
        self.name   = name
    }
}

// MARK: - Card

struct ShareCardView: View {

    let weeks:              [LifeWeek]
    let progress:           Double
    let weeksLived:         Int
    let lifeExpectancyYears: Int
    var config:             ShareConfig = ShareConfig()

    private let columns  = 52
    private let cellSize: CGFloat = 4
    private let cellGap:  CGFloat = 1.5

    var body: some View {
        ZStack {
            background
            switch config.layout {
            case .poster:  posterLayout
            case .square:  squareLayout
            case .minimal: minimalLayout
            }
        }
        .frame(width: config.layout.size.width, height: config.layout.size.height)
    }

    // MARK: - Layouts

    private var posterLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            headlineBlock
            Spacer()
            gridCanvas
            Spacer()
            statsRow
            Spacer()
            brandLabel
        }
        .padding(.horizontal, 28)
        .padding(.vertical, 40)
    }

    private var squareLayout: some View {
        VStack(spacing: 0) {
            headlineBlock
                .padding(.top, 24)
            Spacer()
            gridCanvas
            Spacer()
            brandLabel
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 24)
    }

    private var minimalLayout: some View {
        VStack(spacing: 0) {
            Spacer()
            gridCanvas
            Spacer()
            HStack {
                Text("\(Int((progress * 100).rounded()))% lived")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.6))
                Spacer()
                brandLabel
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
    }

    // MARK: - Reusable sub-views

    private var headlineBlock: some View {
        VStack(spacing: 6) {
            if !config.name.isEmpty {
                Text(config.name)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(1.5)
            }
            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: 68, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            Text("of life lived")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
        }
    }

    private var gridCanvas: some View {
        let rows  = lifeExpectancyYears
        let gridW = CGFloat(columns) * (cellSize + cellGap) - cellGap
        let gridH = CGFloat(rows)    * (cellSize + cellGap) - cellGap

        return Canvas { context, _ in
            for week in weeks {
                let col = week.index % columns
                let row = week.index / columns
                guard row < rows else { continue }

                let x    = CGFloat(col) * (cellSize + cellGap)
                let y    = CGFloat(row) * (cellSize + cellGap)
                let rect = CGRect(x: x, y: y, width: cellSize, height: cellSize)
                let path = Path(roundedRect: rect, cornerRadius: 1.2)

                let color: Color
                switch week.state {
                case .past:    color = .white.opacity(0.80)
                case .current: color = Color.accentColor
                case .future:  color = .white.opacity(0.11)
                }
                context.fill(path, with: .color(color))
            }
        }
        .frame(width: gridW, height: gridH)
    }

    private var statsRow: some View {
        HStack(spacing: 28) {
            statItem(value: weeksLived,
                     label: "weeks lived")
            statItem(value: max(lifeExpectancyYears * 52 - weeksLived, 0),
                     label: "weeks ahead")
        }
    }

    private func statItem(value: Int, label: String) -> some View {
        VStack(spacing: 3) {
            Text("\(value)")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(.white)
            Text(label)
                .font(.system(size: 10, design: .rounded))
                .foregroundStyle(.white.opacity(0.4))
        }
    }

    private var brandLabel: some View {
        Text("Life in Weeks")
            .font(.system(size: 11, weight: .medium, design: .rounded))
            .foregroundStyle(.white.opacity(0.2))
            .tracking(2)
            .textCase(.uppercase)
    }

    private var background: some View {
        LinearGradient(
            colors: [Color(white: 0.08), Color(white: 0.03)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Preview

#Preview {
    let weeks = LifeCalculator.generateWeeks(
        birthDate: Calendar.current.date(byAdding: .year, value: -30, to: Date())!,
        lifeExpectancyYears: 80
    )
    return VStack(spacing: 16) {
        ForEach(ShareLayout.allCases) { layout in
            ShareCardView(
                weeks: weeks, progress: 0.375,
                weeksLived: 1560, lifeExpectancyYears: 80,
                config: ShareConfig(layout: layout, name: "Alex")
            )
            .scaleEffect(0.4)
            .frame(height: layout.size.height * 0.4)
        }
    }
    .padding()
    .background(.black)
}
