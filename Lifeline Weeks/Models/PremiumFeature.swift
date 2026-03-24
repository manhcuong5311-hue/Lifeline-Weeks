import Foundation

enum PremiumFeature: String, CaseIterable {
    case themes      = "Themes"
    case milestones  = "Milestones"
    case exportImage = "Export Image"

    var description: String {
        switch self {
        case .themes:      return "Personalise your grid with beautiful colour themes"
        case .milestones:  return "Mark and celebrate key moments in your life"
        case .exportImage: return "Save your life grid as a shareable image"
        }
    }

    var systemImage: String {
        switch self {
        case .themes:      return "paintpalette.fill"
        case .milestones:  return "star.fill"
        case .exportImage: return "square.and.arrow.up.fill"
        }
    }
}
