import Foundation

struct MilestoneEngine {

    private nonisolated static let fractions: [(Double, String)] = [
        (0.25, "Quarter Life"),
        (0.50, "Half Life"),
        (0.75, "Three Quarters")
    ]

    nonisolated static func milestones(totalWeeks: Int, weeksLived: Int) -> [Milestone] {
        fractions.map { fraction, title in
            let weekIndex = Int(Double(totalWeeks) * fraction)
            return Milestone(
                title: title,
                fraction: fraction,
                weekIndex: weekIndex,
                isReached: weeksLived >= weekIndex
            )
        }
    }

    nonisolated static func milestoneIndices(totalWeeks: Int) -> Set<Int> {
        Set(fractions.map { fraction, _ in
            Int(Double(totalWeeks) * fraction)
        })
    }

    nonisolated static func newlyCrossed(from oldWeeks: Int, to newWeeks: Int, totalWeeks: Int) -> Milestone? {
        let all = milestones(totalWeeks: totalWeeks, weeksLived: newWeeks)
        return all.first { m in
            m.isReached && oldWeeks < m.weekIndex && newWeeks >= m.weekIndex
        }
    }
}
