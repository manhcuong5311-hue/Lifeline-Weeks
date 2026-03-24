import Foundation

struct Milestone: Identifiable, Equatable {
    let id: UUID
    let title: String
    let fraction: Double   // 0.25, 0.50, 0.75
    let weekIndex: Int
    let isReached: Bool

    nonisolated init(title: String, fraction: Double, weekIndex: Int, isReached: Bool) {
        self.id        = UUID()
        self.title     = title
        self.fraction  = fraction
        self.weekIndex = weekIndex
        self.isReached = isReached
    }
}
