import Foundation

struct LifeCalculator {

    // MARK: - Public API

    nonisolated static func generateWeeks(birthDate: Date, lifeExpectancyYears: Int) -> [LifeWeek] {
        let calendar   = Calendar.current
        let totalWeeks = max(0, lifeExpectancyYears * 52)
        let now        = Date()

        guard birthDate <= now else { return [] }

        var weeks: [LifeWeek] = []
        weeks.reserveCapacity(totalWeeks)

        let weekStart = mondayOfWeek(containing: birthDate, calendar: calendar)

        for index in 0..<totalWeeks {
            guard let start = calendar.date(byAdding: .weekOfYear, value: index, to: weekStart),
                  let end   = calendar.date(byAdding: .day, value: 6, to: start) else { continue }
            weeks.append(LifeWeek(index: index, startDate: start, endDate: end,
                                  state: weekState(start: start, end: end, now: now)))
        }
        return weeks
    }

    nonisolated static func stats(birthDate: Date, lifeExpectancyYears: Int) -> (lived: Int, total: Int, progress: Double) {
        let lived    = currentWeekIndex(birthDate: birthDate)
        let total    = max(1, lifeExpectancyYears * 52)
        let progress = min(max(Double(lived) / Double(total), 0), 1)
        return (lived, total, progress)
    }

    nonisolated static func calculateProgress(birthDate: Date, lifeExpectancyYears: Int) -> Double {
        stats(birthDate: birthDate, lifeExpectancyYears: lifeExpectancyYears).progress
    }

    nonisolated static func currentWeekIndex(birthDate: Date) -> Int {
        guard birthDate <= Date() else { return 0 }
        let calendar    = Calendar.current
        let now         = Date()
        let birthMonday = mondayOfWeek(containing: birthDate, calendar: calendar)
        let nowMonday   = mondayOfWeek(containing: now, calendar: calendar)
        let components  = calendar.dateComponents([.weekOfYear], from: birthMonday, to: nowMonday)
        return max(components.weekOfYear ?? 0, 0)
    }

    nonisolated static func totalWeeks(lifeExpectancyYears: Int) -> Int { lifeExpectancyYears * 52 }
    nonisolated static func weeksLived(birthDate: Date) -> Int          { currentWeekIndex(birthDate: birthDate) }

    // MARK: - Private helpers

    private nonisolated static func weekState(start: Date, end: Date, now: Date) -> WeekState {
        // 'end' = start-of-Sunday (6 days after Monday midnight).
        // The week is still "current" for the whole of Sunday, so we compare
        // against the START of next Monday (end + 1 day) instead of end itself.
        let nextMonday = Calendar.current.date(byAdding: .day, value: 1, to: end) ?? end
        if now >= nextMonday { return .past }
        if now >= start      { return .current }
        return .future
    }

    private nonisolated static func mondayOfWeek(containing date: Date, calendar: Calendar) -> Date {
        var cal = calendar
        cal.timeZone = .current
        let weekday        = cal.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        let monday         = cal.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        return cal.startOfDay(for: monday)
    }
}
