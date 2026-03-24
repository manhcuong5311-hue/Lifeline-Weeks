import UserNotifications
import Foundation

// MARK: - Schedule model

struct NotificationSchedule: Codable, Equatable {
    var weekday: Int = 2    // 1 = Sun … 7 = Sat  (default Monday)
    var hour:    Int = 9
    var minute:  Int = 0

    static let `default` = NotificationSchedule()

    var weekdayName: String {
        let symbols = Calendar.current.weekdaySymbols
        let idx     = max(0, min(weekday - 1, symbols.count - 1))
        return symbols[idx]
    }
}

// MARK: - Service

struct NotificationService {

    // MARK: - Notification identifiers

    private static let primaryID       = "life.weeklyReminder"   // repeating: user-chosen day
    private static let sundayID        = "life.sundayReflection" // repeating: Sunday 8 pm
    private static let birthdayID      = "life.birthday"         // one-shot: next birthday
    private static let milestonePrefix = "life.milestone"

    // MARK: - UserDefaults keys

    private static let enabledKey      = "life.notificationsEnabled"
    private static let scheduleKey     = "life.notificationSchedule"
    private static let toneKey         = "life.notificationTone"
    private static let recentBodiesKey = "life.recentNotificationBodies"

    // MARK: - Persisted schedule

    static var schedule: NotificationSchedule {
        get {
            guard let data   = UserDefaults.standard.data(forKey: scheduleKey),
                  let stored = try? JSONDecoder().decode(NotificationSchedule.self, from: data)
            else { return .default }
            return stored
        }
        set {
            if let data = try? JSONEncoder().encode(newValue) {
                UserDefaults.standard.set(data, forKey: scheduleKey)
            }
        }
    }

    // MARK: - Persisted tone

    static var tone: NotificationTone {
        get {
            guard let raw = UserDefaults.standard.string(forKey: toneKey),
                  let t   = NotificationTone(rawValue: raw)
            else { return .balanced }
            return t
        }
        set { UserDefaults.standard.set(newValue.rawValue, forKey: toneKey) }
    }

    // MARK: - Enabled flag

    static var isEnabled: Bool {
        UserDefaults.standard.bool(forKey: enabledKey)
    }

    // MARK: - Anti-spam (rolling buffer of last 10 shown message bodies)

    static var recentBodies: [String] {
        get { UserDefaults.standard.stringArray(forKey: recentBodiesKey) ?? [] }
        set { UserDefaults.standard.set(Array(newValue.suffix(10)), forKey: recentBodiesKey) }
    }

    private static func recordShown(_ body: String) {
        var buf = recentBodies
        buf.append(body)
        recentBodies = buf
    }

    // MARK: - Public API

    static func requestAndSchedule(
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone,
        completion: @escaping (Bool) -> Void
    ) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    if granted {
                        UserDefaults.standard.set(true, forKey: enabledKey)
                        scheduleAll(birthDate: birthDate, weeksLived: weeksLived,
                                    weeksRemaining: weeksRemaining, tone: tone)
                    }
                    completion(granted)
                }
            }
    }

    static func updateSchedule(
        _ newSchedule: NotificationSchedule,
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone
    ) {
        schedule = newSchedule
        guard isEnabled else { return }
        scheduleAll(birthDate: birthDate, weeksLived: weeksLived,
                    weeksRemaining: weeksRemaining, tone: tone)
    }

    static func updateTone(
        _ newTone: NotificationTone,
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int
    ) {
        Self.tone = newTone
        guard isEnabled else { return }
        scheduleAll(birthDate: birthDate, weeksLived: weeksLived,
                    weeksRemaining: weeksRemaining, tone: newTone)
    }

    static func rescheduleIfNeeded(
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone
    ) {
        guard isEnabled else { return }
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                UserDefaults.standard.set(false, forKey: enabledKey)
                return
            }
            scheduleAll(birthDate: birthDate, weeksLived: weeksLived,
                        weeksRemaining: weeksRemaining, tone: tone)
        }
    }

    /// No-arg version called at app launch — loads profile from persistence.
    static func rescheduleIfNeeded() {
        guard isEnabled else { return }
        guard let profile = PersistenceService.load() else { return }
        let s = LifeCalculator.stats(
            birthDate: profile.birthDate,
            lifeExpectancyYears: profile.lifeExpectancy
        )
        rescheduleIfNeeded(
            birthDate: profile.birthDate,
            weeksLived: s.lived,
            weeksRemaining: max(s.total - s.lived, 0),
            tone: tone
        )
    }

    static func disable() {
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [primaryID, sundayID, birthdayID])
        // Remove any queued milestone notifications
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            let ids = requests.map(\.identifier).filter { $0.hasPrefix(milestonePrefix) }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ids)
        }
        UserDefaults.standard.set(false, forKey: enabledKey)
    }

    /// Schedule a one-shot notification exactly when the user crosses a milestone week.
    static func scheduleMilestoneNotification(milestone: Milestone, on date: Date) {
        guard isEnabled else { return }
        let content   = UNMutableNotificationContent()
        content.title = "✦ \(milestone.title)"
        content.body  = "Open your life grid to see this moment."
        content.sound = .default

        let comps   = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(
            identifier: "\(milestonePrefix).\(milestone.id)",
            content: content,
            trigger: trigger
        )
        UNUserNotificationCenter.current().add(request)
    }

    // MARK: - Scheduling orchestration

    private static func scheduleAll(
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone
    ) {
        schedulePrimary(birthDate: birthDate, weeksLived: weeksLived,
                        weeksRemaining: weeksRemaining, tone: tone)
        scheduleSecondary(weeksLived: weeksLived, weeksRemaining: weeksRemaining, tone: tone)
        scheduleBirthday(birthDate: birthDate, weeksLived: weeksLived,
                         weeksRemaining: weeksRemaining, tone: tone)
    }

    /// Primary weekly — user-chosen day / time, context-aware content.
    private static func schedulePrimary(
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [primaryID])

        let ctx     = NotificationContextDetector.detect(birthDate: birthDate,
                                                         weeksLived: weeksLived,
                                                         weeksRemaining: weeksRemaining)
        let payload = NotificationContentEngine.generate(
            context: ctx, tone: tone,
            weeksLived: weeksLived, weeksRemaining: weeksRemaining,
            recentBodies: recentBodies
        )
        recordShown(payload.body)

        let content   = UNMutableNotificationContent()
        content.title = payload.title
        content.body  = payload.body
        content.sound = .default

        let s  = schedule
        var dc = DateComponents()
        dc.weekday = s.weekday
        dc.hour    = s.hour
        dc.minute  = s.minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        center.add(UNNotificationRequest(identifier: primaryID, content: content, trigger: trigger))
    }

    /// Secondary: Sunday 8 pm reflection — skipped if primary is already Sunday.
    /// Gives users a gentle end-of-weekend nudge without extra settings.
    private static func scheduleSecondary(
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone
    ) {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [sundayID])

        guard schedule.weekday != 1 else { return }   // primary already covers Sunday

        let payload = NotificationContentEngine.generate(
            context: .weeklyReflection, tone: tone,
            weeksLived: weeksLived, weeksRemaining: weeksRemaining,
            recentBodies: recentBodies
        )
        recordShown(payload.body)

        let content   = UNMutableNotificationContent()
        content.title = payload.title
        content.body  = payload.body
        content.sound = .default

        var dc     = DateComponents()
        dc.weekday = 1    // Sunday
        dc.hour    = 20   // 8 pm
        dc.minute  = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dc, repeats: true)
        center.add(UNNotificationRequest(identifier: sundayID, content: content, trigger: trigger))
    }

    /// One-shot birthday notification for the next occurrence of the user's birthday.
    /// Re-scheduled each time `scheduleAll` runs — stays current automatically.
    private static func scheduleBirthday(
        birthDate: Date,
        weeksLived: Int,
        weeksRemaining: Int,
        tone: NotificationTone
    ) {
        let center   = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [birthdayID])

        let calendar = Calendar.current
        let now      = Date()
        let year     = calendar.component(.year, from: now)

        // Build a DateComponents for the birthday this calendar year
        // Feb 29 birthday: fall back to Feb 28 in non-leap years so the
        // notification is never silently dropped.
        var comps    = calendar.dateComponents([.month, .day], from: birthDate)
        let isLeapBirthday = comps.month == 2 && comps.day == 29
        comps.hour   = 9
        comps.minute = 0

        // Helper: build a Date for a given year, handling Feb 29 fallback
        func birthdayDate(in targetYear: Int) -> Date? {
            var c      = comps
            c.year     = targetYear
            if let d = calendar.date(from: c) { return d }
            if isLeapBirthday { c.day = 28; return calendar.date(from: c) }
            return nil
        }

        // If this year's birthday has passed, push to next year
        let target: Date
        if let thisYear = birthdayDate(in: year), thisYear > now {
            target = thisYear
        } else {
            guard let nextYear = birthdayDate(in: year + 1) else { return }
            target = nextYear
        }

        let turningAge = weeksLived / 52 + 1
        let payload    = NotificationContentEngine.generate(
            context: .birthdayWeek(age: turningAge), tone: tone,
            weeksLived: weeksLived, weeksRemaining: weeksRemaining,
            recentBodies: []   // birthday is always special — bypass anti-spam
        )

        let content   = UNMutableNotificationContent()
        content.title = payload.title
        content.body  = payload.body
        content.sound = .default

        let triggerComps = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: target)
        let trigger      = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        center.add(UNNotificationRequest(identifier: birthdayID, content: content, trigger: trigger))
    }
}
