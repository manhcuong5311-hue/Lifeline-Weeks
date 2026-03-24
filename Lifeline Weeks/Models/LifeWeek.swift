import Foundation

enum WeekState: Equatable {
    case past
    case current
    case future
}

struct LifeWeek: Identifiable {
    let id: UUID
    let index: Int
    let startDate: Date
    let endDate: Date
    let state: WeekState

    nonisolated init(index: Int, startDate: Date, endDate: Date, state: WeekState) {
        self.id = UUID()
        self.index = index
        self.startDate = startDate
        self.endDate = endDate
        self.state = state
    }
}
