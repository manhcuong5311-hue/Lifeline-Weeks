import SwiftUI

struct WeekDetailView: View {
    let week:      LifeWeek
    var birthDate: Date = Date()

    var body: some View {
        VStack(spacing: DS.Spacing.xl) {
            // Drag handle
            Capsule()
                .fill(Color.appDivider)
                .frame(width: 36, height: 4)
                .padding(.top, DS.Spacing.m)

            // State badge
            Text(stateLabel)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(stateColor)
                .padding(.horizontal, DS.Spacing.m)
                .padding(.vertical, DS.Spacing.xs)
                .background(stateColor.opacity(0.12), in: Capsule())

            // Primary info
            VStack(spacing: DS.Spacing.s) {
                Text(primaryHeadline)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                    .multilineTextAlignment(.center)

                Text(ageContext)
                    .font(.system(size: 15, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
            }

            // Date range
            Text(dateRange)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.textTertiary)

            // Emotional line for current week
            if week.state == .current {
                Text("You are living this week right now.")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.weekCurrent)
                    .italic()
            }

            Spacer()
        }
        .frame(maxWidth: .infinity)
        .background(Color.appBgElevated)
        .presentationDetents([.height(week.state == .current ? 280 : 240)])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    // MARK: - Computed

    private var primaryHeadline: String {
        switch week.state {
        case .past:    return "Week \(week.index + 1)"
        case .current: return "This week"
        case .future:  return "Week \(week.index + 1)"
        }
    }

    private var ageContext: String {
        let calendar  = Calendar.current
        let age       = max(0, calendar.dateComponents([.year], from: birthDate, to: week.startDate).year ?? 0)
        let yearStart = calendar.date(byAdding: .year, value: age, to: birthDate) ?? birthDate
        let dayInYear = calendar.dateComponents([.day], from: yearStart, to: week.startDate).day ?? 0
        let weekInYear = dayInYear / 7 + 1
        switch week.state {
        case .past:    return "Age \(age) · Week \(weekInYear) of that year"
        case .current: return "Age \(age) · Week \(weekInYear) of this year"
        case .future:  return "Age \(age) · Week \(weekInYear) of that year"
        }
    }

    private var stateLabel: String {
        switch week.state {
        case .past:    return "Past"
        case .current: return "This week"
        case .future:  return "Future"
        }
    }

    private var stateColor: Color {
        switch week.state {
        case .past:    return Color.textSecondary
        case .current: return Color.weekCurrent
        case .future:  return Color.textTertiary
        }
    }

    private var dateRange: String {
        "\(Self.fmt.string(from: week.startDate)) – \(Self.fmt.string(from: week.endDate))"
    }

    private static let fmt: DateFormatter = {
        let f = DateFormatter(); f.dateStyle = .medium; f.timeStyle = .none; return f
    }()
}

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        let week = LifeWeek(
            index: 1559,
            startDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            endDate:   Calendar.current.date(byAdding: .day, value:  3, to: Date())!,
            state: .current
        )
        WeekDetailView(week: week)
    }
}
