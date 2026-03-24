import Foundation
import Combine

@MainActor
final class LifeViewModel: ObservableObject {

    // MARK: - Persisted state

    @Published var birthDate: Date {
        didSet { saveData(); scheduleRegeneration() }
    }

    @Published var lifeExpectancy: Int {
        didSet { saveData(); scheduleRegeneration() }
    }

    @Published var userName: String = ""

    // MARK: - Onboarding gate

    @Published private(set) var hasConfigured: Bool = false  // use hasConfigured_reset() to clear

    // MARK: - Premium

    @Published var isPremium: Bool = PremiumService.isPremium {
        didSet { PremiumService.isPremium = isPremium }
    }

    func isUnlocked(_ feature: PremiumFeature) -> Bool { PremiumService.isUnlocked(feature) }

    // MARK: - Notifications

    @Published var notificationsEnabled: Bool = NotificationService.isEnabled {
        didSet {
            if notificationsEnabled {
                NotificationService.requestAndSchedule(
                    birthDate: birthDate,
                    weeksLived: weeksLived,
                    weeksRemaining: weeksRemaining,
                    tone: notificationTone
                ) { [weak self] granted in
                    if !granted { self?.notificationsEnabled = false }
                }
            } else {
                NotificationService.disable()
            }
        }
    }

    @Published var notificationSchedule: NotificationSchedule = NotificationService.schedule {
        didSet {
            NotificationService.updateSchedule(
                notificationSchedule,
                birthDate: birthDate,
                weeksLived: weeksLived,
                weeksRemaining: weeksRemaining,
                tone: notificationTone
            )
        }
    }

    @Published var notificationTone: NotificationTone = NotificationService.tone {
        didSet {
            NotificationService.updateTone(
                notificationTone,
                birthDate: birthDate,
                weeksLived: weeksLived,
                weeksRemaining: weeksRemaining
            )
        }
    }

    // MARK: - Derived state (read-only)

    @Published private(set) var weeks:          [LifeWeek]  = []
    @Published private(set) var weeksLived:     Int         = 0
    @Published private(set) var weeksRemaining: Int         = 0
    @Published private(set) var progress:       Double      = 0
    @Published private(set) var milestones:     [Milestone] = []
    @Published private(set) var milestoneIndices: Set<Int>  = []
    @Published private(set) var currentInsight: String      = ""

    // MARK: - In-memory week cache

    private struct WeekCache {
        let birthDate:       Date
        let lifeExpectancy:  Int
        let generatedOnWeek: Int           // currentWeekIndex at generation time
        let weeks:           [LifeWeek]
    }
    private var weekCache: WeekCache?

    // MARK: - Defaults

    private static let defaultLifeExpectancy = 90
    private static let defaultBirthDate: Date = {
        Calendar.current.date(from: DateComponents(year: 1990, month: 1, day: 1)) ?? Date()
    }()

    // MARK: - Task management

    private var generationTask: Task<Void, Never>?

    // MARK: - Init

    init() {
        self.birthDate      = Self.defaultBirthDate
        self.lifeExpectancy = Self.defaultLifeExpectancy
        loadData()
    }

    // MARK: - Persistence

    func loadData() {
        guard let profile = PersistenceService.load() else { return }
        _birthDate      = Published(initialValue: profile.birthDate)
        _lifeExpectancy = Published(initialValue: profile.lifeExpectancy)
        userName        = profile.name
        hasConfigured   = true
        scheduleRegeneration()
        // Keep widget in sync on every app launch
        WidgetSyncService.sync(birthDate: profile.birthDate, lifeExpectancy: profile.lifeExpectancy)
    }

    func saveData() {
        let profile = UserProfile(birthDate: birthDate, lifeExpectancy: lifeExpectancy, name: userName).sanitised()
        PersistenceService.save(profile)
        hasConfigured = true
        // Push data to App Group so the widget can read it
        WidgetSyncService.sync(birthDate: profile.birthDate, lifeExpectancy: profile.lifeExpectancy)
    }

    /// Wipes persisted data and returns the app to onboarding state.
    func hasConfigured_reset() {
        generationTask?.cancel()
        weeks            = []
        weeksLived       = 0
        weeksRemaining   = 0
        progress         = 0
        currentInsight   = ""
        milestones       = []
        milestoneIndices = []
        weekCache        = nil
        hasConfigured    = false
        NotificationService.disable()
        WidgetSyncService.clear()
    }

    // MARK: - Week generation

    func regenerateWeeks() { scheduleRegeneration() }

    private func scheduleRegeneration() {
        generationTask?.cancel()

        let birthDate      = self.birthDate
        let lifeExpectancy = self.lifeExpectancy
        let cachedResult   = weekCache

        generationTask = Task.detached(priority: .userInitiated) { [weak self] in
            guard !Task.isCancelled else { return }

            let currentWeek = LifeCalculator.currentWeekIndex(birthDate: birthDate)

            // Use cache if inputs and current week are unchanged
            let generated: [LifeWeek]
            if let cache = cachedResult,
               cache.birthDate == birthDate,
               cache.lifeExpectancy == lifeExpectancy,
               cache.generatedOnWeek == currentWeek {
                generated = cache.weeks
            } else {
                generated = LifeCalculator.generateWeeks(
                    birthDate: birthDate,
                    lifeExpectancyYears: lifeExpectancy
                )
            }

            guard !Task.isCancelled else { return }

            let s            = LifeCalculator.stats(birthDate: birthDate, lifeExpectancyYears: lifeExpectancy)
            let totalWeeks   = s.total
            let newMilestones = MilestoneEngine.milestones(totalWeeks: totalWeeks, weeksLived: s.lived)
            let indices       = MilestoneEngine.milestoneIndices(totalWeeks: totalWeeks)
            let insight       = InsightEngine.rotatingInsight(
                weeksLived: s.lived,
                weeksRemaining: max(totalWeeks - s.lived, 0),
                progress: s.progress,
                birthDate: birthDate
            )

            guard !Task.isCancelled else { return }

            let newCache = WeekCache(
                birthDate: birthDate,
                lifeExpectancy: lifeExpectancy,
                generatedOnWeek: currentWeek,
                weeks: generated
            )

            await MainActor.run { [weak self] in
                guard let self, !Task.isCancelled else { return }
                self.weekCache        = newCache
                self.weeks            = generated
                self.weeksLived       = s.lived
                self.weeksRemaining   = max(s.total - s.lived, 0)
                self.progress         = s.progress
                self.milestones       = newMilestones
                self.milestoneIndices = indices
                self.currentInsight   = insight.text

                // Reschedule with full context
                if self.notificationsEnabled {
                    NotificationService.rescheduleIfNeeded(
                        birthDate: self.birthDate,
                        weeksLived: self.weeksLived,
                        weeksRemaining: self.weeksRemaining,
                        tone: self.notificationTone
                    )
                }
            }
        }
    }
}
