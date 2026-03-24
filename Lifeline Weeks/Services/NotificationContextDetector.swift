import Foundation

/// Analyzes today's date + user stats to pick the most contextually relevant
/// notification category. Special moments (birthday, new year, milestones,
/// decade entries) take precedence over the regular weekly rotation.
struct NotificationContextDetector {

    nonisolated static func detect(
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int
    ) -> NotificationContext {
        let calendar = Calendar.current
        let today    = Date()
        let age      = weeksLived / 52
        let month    = calendar.component(.month, from: today)
        let day      = calendar.component(.day, from: today)

        // ── 1. Birthday week (within ±3 days of annual anniversary) ────
        if let bday = birthdayAnniversary(of: birthDate, in: calendar.component(.year, from: today)) {
            let deltaDays = abs(calendar.dateComponents([.day], from: today, to: bday).day ?? 99)
            if deltaDays <= 3 {
                return .birthdayWeek(age: age)
            }
        }

        // ── 2. New Year (Jan 1–7) ───────────────────────────────────────
        if month == 1, day <= 7 {
            return .newYear
        }

        // ── 3. Entering a new decade (first 2 weeks after decade birthday) ─
        if age > 0, age % 10 == 0 {
            let weeksIntoCurrent = weeksLived % 520   // 10 years × 52
            if weeksIntoCurrent <= 2 {
                return .enteringDecade(age: age)
            }
        }

        // ── 4. Life milestone ±1 week of 25 / 50 / 75 % ────────────────
        let total = weeksLived + weeksRemaining
        for fraction in [0.25, 0.50, 0.75] {
            let target = Int(Double(total) * fraction)
            if abs(weeksLived - target) <= 1 {
                return .milestone(fraction: fraction, weeksLived: weeksLived)
            }
        }

        // ── 5. Month start (day 1–3) ────────────────────────────────────
        if day <= 3 {
            return .monthStart
        }

        // ── 6. Deterministic weekly rotation ────────────────────────────
        switch weeksLived % 3 {
        case 0:  return .weeklyReflection
        case 1:  return .urgency
        default: return .awareness
        }
    }

    // MARK: - Private

    nonisolated private static func birthdayAnniversary(of birthDate: Date, in year: Int) -> Date? {
        var comps  = Calendar.current.dateComponents([.month, .day], from: birthDate)
        comps.year = year
        if let date = Calendar.current.date(from: comps) { return date }
        // Feb 29 birthday in a non-leap year → fall back to Feb 28
        if comps.month == 2, comps.day == 29 {
            comps.day = 28
            return Calendar.current.date(from: comps)
        }
        return nil
    }
}
