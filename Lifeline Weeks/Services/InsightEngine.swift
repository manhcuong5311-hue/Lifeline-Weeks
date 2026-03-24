import Foundation

struct InsightEngine {

    nonisolated static func rotatingInsight(weeksLived: Int, weeksRemaining: Int,
                                            progress: Double, birthDate: Date) -> Insight {
        let pool = buildPool(weeksLived: weeksLived, weeksRemaining: weeksRemaining,
                             progress: progress, birthDate: birthDate)
        guard !pool.isEmpty else {
            return Insight(text: "Make this week count.", category: .motivational)
        }
        return pool[weeksLived % pool.count]
    }

    // MARK: - Private pool

    private nonisolated static func buildPool(weeksLived: Int, weeksRemaining: Int,
                                              progress: Double, birthDate: Date) -> [Insight] {
        let age     = Calendar.current.dateComponents([.year], from: birthDate, to: Date()).year ?? 0
        let years   = weeksRemaining / 52
        let summers = years
        let xmases  = years
        let decades = weeksRemaining / 520

        var pool: [Insight] = []

        // ---- Fraction / milestone ----
        if progress >= 0.50 {
            pool.append(.init(text: "More than half your life is behind you.", category: .fraction))
        } else if progress >= 0.33 {
            pool.append(.init(text: "A third of your life has already passed.", category: .fraction))
        } else if progress >= 0.25 {
            pool.append(.init(text: "You've used a quarter of your time.", category: .fraction))
        } else {
            pool.append(.init(text: "Most of your life is still ahead of you.", category: .fraction))
        }

        // ---- Time perspective ----
        if xmases > 0 {
            pool.append(.init(text: "You have \(xmases) more Christmases.", category: .time))
        }
        if summers > 0 {
            pool.append(.init(text: "You have \(summers) more summers.", category: .time))
        }
        if decades > 0 {
            pool.append(.init(text: "You have \(decades) more decade\(decades == 1 ? "" : "s").", category: .time))
        }
        pool.append(.init(text: "\(weeksRemaining) weeks remain. Use them well.", category: .statistical))
        pool.append(.init(text: "That's \(years) more years to become who you want to be.", category: .statistical))

        // ---- Age-based motivational ----
        switch age {
        case ..<20:
            pool.append(.init(text: "Your story is only just beginning.", category: .motivational))
        case 20..<30:
            pool.append(.init(text: "These are the years that shape everything after.", category: .motivational))
        case 30..<40:
            pool.append(.init(text: "You know enough now to live deliberately.", category: .motivational))
        case 40..<50:
            pool.append(.init(text: "You are in the middle of your story. Make it count.", category: .motivational))
        case 50..<65:
            pool.append(.init(text: "This chapter defines what you leave behind.", category: .motivational))
        default:
            pool.append(.init(text: "Every week from here is a gift. Don't waste it.", category: .motivational))
        }

        // ---- Universal ----
        pool.append(.init(text: "Time doesn't slow down. You have to.", category: .motivational))
        pool.append(.init(text: "Each filled square is a week you can't get back.", category: .fraction))

        return pool
    }
}
