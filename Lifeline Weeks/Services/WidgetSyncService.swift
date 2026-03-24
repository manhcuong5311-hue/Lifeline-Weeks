import Foundation
import WidgetKit

/// Writes life-data to the shared App Group UserDefaults so the widget extension
/// can read it without depending on the main app target.
///
/// Prerequisites (do once in Xcode):
///   1. Main App target → Signing & Capabilities → + App Groups → "group.life.lifelineweeks"
///   2. LifelineWeek widget target → same capability with same identifier
struct WidgetSyncService {

    // Must match WidgetDataStore.suiteName in the widget extension
    // This must also match the App Group ID registered in Xcode for both targets
    private static let suiteName = "group.life.lifelineweeks"

    private static let birthDateKey       = "widget.birthDate"
    private static let lifeExpectancyKey  = "widget.lifeExpectancy"

    // MARK: - Public API

    /// Call after saving profile changes; reloads all widget timelines.
    static func sync(birthDate: Date, lifeExpectancy: Int) {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.set(birthDate.timeIntervalSince1970, forKey: birthDateKey)
        defaults.set(lifeExpectancy, forKey: lifeExpectancyKey)
        WidgetCenter.shared.reloadAllTimelines()
    }

    /// Call on reset / onboarding revert; clears widget data and reloads.
    static func clear() {
        guard let defaults = UserDefaults(suiteName: suiteName) else { return }
        defaults.removeObject(forKey: birthDateKey)
        defaults.removeObject(forKey: lifeExpectancyKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
