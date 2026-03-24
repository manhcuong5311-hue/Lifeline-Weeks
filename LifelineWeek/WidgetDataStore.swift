import Foundation

// ─────────────────────────────────────────────────────────────
// MARK: - App Group suite name
// ─────────────────────────────────────────────────────────────
// IMPORTANT: This must match the App Group ID added in Xcode →
//   Main App Target  → Signing & Capabilities → App Groups
//   Widget Extension → Signing & Capabilities → App Groups
//   Use identifier:  group.com.SamCorp.Lifeline-Weeks.LifelineWeek
// ─────────────────────────────────────────────────────────────

enum WidgetDataStore {

    static let suiteName         = "group.life.lifelineweeks"

    private static let birthDateKey      = "widget.birthDate"
    private static let lifeExpectancyKey = "widget.lifeExpectancy"
    private static let recentMsgIDsKey   = "widget.recentMessageIDs"

    // MARK: - Write (main app → widget)

    static func save(birthDate: Date, lifeExpectancy: Int) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(birthDate.timeIntervalSince1970, forKey: birthDateKey)
        defaults.set(lifeExpectancy, forKey: lifeExpectancyKey)
    }

    static func clear() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: birthDateKey)
        defaults.removeObject(forKey: lifeExpectancyKey)
    }

    // MARK: - Read (widget)

    static func loadProfile() -> (birthDate: Date, lifeExpectancy: Int)? {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return nil }
        let ts = defaults.double(forKey: birthDateKey)
        let le = defaults.integer(forKey: lifeExpectancyKey)
        guard ts > 0, le > 0 else { return nil }
        return (Date(timeIntervalSince1970: ts), le)
    }

    // MARK: - Anti-repetition (rolling 14-ID buffer)

    static var recentMessageIDs: [String] {
        get { UserDefaults(suiteName: suiteName)?.stringArray(forKey: recentMsgIDsKey) ?? [] }
        set { UserDefaults(suiteName: suiteName)?.set(Array(newValue.suffix(14)), forKey: recentMsgIDsKey) }
    }

    static func recordShown(_ id: String) {
        var ids = recentMessageIDs
        ids.append(id)
        recentMessageIDs = ids
    }

    // MARK: - Compute stats (self-contained, no dependency on main app)

    static func computeStats(birthDate: Date, lifeExpectancy: Int) -> WidgetStats {
        let calendar   = Calendar.current
        let now        = Date()
        let totalWeeks = lifeExpectancy * 52
        let totalDays  = lifeExpectancy * 365

        // Weeks lived (Monday-aligned, same algorithm as LifeCalculator)
        let birthMonday = mondayOfWeek(containing: birthDate, using: calendar)
        let nowMonday   = mondayOfWeek(containing: now,       using: calendar)
        let weekComps   = calendar.dateComponents([.weekOfYear], from: birthMonday, to: nowMonday)
        let weeksLived  = max(weekComps.weekOfYear ?? 0, 0)

        // Days lived
        let dayComps   = calendar.dateComponents(
            [.day],
            from: calendar.startOfDay(for: birthDate),
            to:   calendar.startOfDay(for: now)
        )
        let daysLived  = max(dayComps.day ?? 0, 0)

        let weeksRemaining = max(totalWeeks - weeksLived, 0)
        let daysRemaining  = max(totalDays  - daysLived,  0)
        let progress       = min(max(Double(weeksLived) / Double(max(totalWeeks, 1)), 0), 1)

        return WidgetStats(
            weeksLived:     weeksLived,
            weeksRemaining: weeksRemaining,
            daysLived:      daysLived,
            daysRemaining:  daysRemaining,
            progress:       progress,
            totalWeeks:     totalWeeks
        )
    }

    private static func mondayOfWeek(containing date: Date, using calendar: Calendar) -> Date {
        var cal = calendar
        cal.timeZone = .current
        let weekday        = cal.component(.weekday, from: date)
        let daysFromMonday = (weekday + 5) % 7
        let monday         = cal.date(byAdding: .day, value: -daysFromMonday, to: date) ?? date
        return cal.startOfDay(for: monday)
    }
}

// MARK: - Stats model

struct WidgetStats {
    let weeksLived:     Int
    let weeksRemaining: Int
    let daysLived:      Int
    let daysRemaining:  Int
    let progress:       Double
    let totalWeeks:     Int

    var progressPercent: Int { Int((progress * 100).rounded()) }
    var yearsRemaining:  Int { weeksRemaining / 52 }

    // Formatted strings — locale-aware commas
    var weeksLivedFormatted:     String { weeksLived.formatted(.number) }
    var weeksRemainingFormatted: String { weeksRemaining.formatted(.number) }
    var totalWeeksFormatted:     String { totalWeeks.formatted(.number) }
}
