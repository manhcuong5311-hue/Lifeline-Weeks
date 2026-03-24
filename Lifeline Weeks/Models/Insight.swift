import Foundation

struct Insight: Identifiable, Equatable {
    let id: UUID
    let text: String
    let category: Category

    enum Category {
        case fraction, time, motivational, statistical
    }

    nonisolated init(text: String, category: Category) {
        self.id       = UUID()
        self.text     = text
        self.category = category
    }
}
