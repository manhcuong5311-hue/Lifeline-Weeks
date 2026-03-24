import Foundation

// MARK: - Tone

enum NotificationTone: String, CaseIterable, Codable, Identifiable {
    case gentle   = "Gentle"
    case balanced = "Balanced"
    case deep     = "Deep"

    var id: String { rawValue }

    var tagline: String {
        switch self {
        case .gentle:   return "Calm · Reflective"
        case .balanced: return "Aware · Motivated"
        case .deep:     return "Existential · Visceral"
        }
    }
}

// MARK: - Context

enum NotificationContext: Equatable {
    case weeklyReflection
    case birthdayWeek(age: Int)
    case newYear
    case monthStart
    case milestone(fraction: Double, weeksLived: Int)
    case enteringDecade(age: Int)
    case awareness
    case urgency
}

// MARK: - Payload

struct NotificationPayload {
    let title: String
    let body: String     // ≤ 80 chars for lock-screen legibility
}

// MARK: - Engine

struct NotificationContentEngine {

    // MARK: - Public API

    /// Select the best non-recently-shown message for this context.
    nonisolated static func generate(
        context: NotificationContext,
        tone: NotificationTone,
        weeksLived: Int,
        weeksRemaining: Int,
        recentBodies: [String]
    ) -> NotificationPayload {
        let candidates = pool(context: context, tone: tone,
                              weeksLived: weeksLived, weeksRemaining: weeksRemaining)
        let filtered   = candidates.filter { !recentBodies.contains($0.body) }
        let source     = filtered.isEmpty ? candidates : filtered
        // Deterministic rotation: varies by both week and context type
        let idx        = (weeksLived + contextSeed(context)) % max(source.count, 1)
        return source[idx % source.count]
    }

    /// 3 preview messages for the settings screen.
    nonisolated static func previewPayloads(
        tone: NotificationTone,
        weeksLived: Int,
        weeksRemaining: Int
    ) -> [NotificationPayload] {
        let yearsLeft = weeksRemaining / 52
        let p         = percentage(weeksLived: weeksLived, weeksRemaining: weeksRemaining)

        switch tone {
        case .gentle:
            return [
                NotificationPayload(title: "Week gone",
                                    body: "One more week lived. You're still here."),
                NotificationPayload(title: "Reflect",
                                    body: "Another week behind you. How was it spent?"),
                NotificationPayload(title: "Your life",
                                    body: "~\(yearsLeft) years of weeks still ahead of you."),
            ]
        case .balanced:
            return [
                NotificationPayload(title: "Week \(weeksLived) done",
                                    body: "~\(weeksRemaining) weeks left. Make them count."),
                NotificationPayload(title: "\(p)% of your life",
                                    body: "\(weeksLived) weeks lived. \(weeksRemaining) ahead."),
                NotificationPayload(title: "Time is moving",
                                    body: "Quietly, steadily. Are you moving with it?"),
            ]
        case .deep:
            return [
                NotificationPayload(title: "Week \(weeksLived): gone.",
                                    body: "\(weeksRemaining) remain. Weeks don't come back."),
                NotificationPayload(title: "\(p)% lived.",
                                    body: "The rest is still up to you."),
                NotificationPayload(title: "Time doesn't slow down.",
                                    body: "You have to."),
            ]
        }
    }

    // MARK: - Helpers

    nonisolated private static func contextSeed(_ ctx: NotificationContext) -> Int {
        switch ctx {
        case .weeklyReflection:    return 0
        case .birthdayWeek:        return 7
        case .newYear:             return 13
        case .monthStart:          return 3
        case .milestone:           return 17
        case .enteringDecade:      return 29
        case .awareness:           return 5
        case .urgency:             return 11
        }
    }

    nonisolated private static func percentage(weeksLived: Int, weeksRemaining: Int) -> Int {
        let total = weeksLived + weeksRemaining
        guard total > 0 else { return 0 }
        return Int(Double(weeksLived) / Double(total) * 100)
    }

    // MARK: - Message pools (all bodies ≤ 80 chars)

    nonisolated private static func pool(
        context: NotificationContext,
        tone: NotificationTone,
        weeksLived: Int,
        weeksRemaining: Int
    ) -> [NotificationPayload] {

        let age       = weeksLived / 52
        let yearsLeft = weeksRemaining / 52
        let p         = percentage(weeksLived: weeksLived, weeksRemaining: weeksRemaining)

        switch context {

        // ── Birthday week ───────────────────────────────────────────────
        case .birthdayWeek(let a):
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "Happy birthday",
                                        body: "You've completed \(a) full years of life."),
                    NotificationPayload(title: "Another year",
                                        body: "Year \(a) is behind you. Year \(a + 1) begins now."),
                    NotificationPayload(title: "Year \(a) done",
                                        body: "A fresh set of 52 weeks just opened."),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "Year \(a) complete",
                                        body: "52 more weeks gone. What did you build?"),
                    NotificationPayload(title: "You turned \(a)",
                                        body: "\(a) years lived. The rest is still unwritten."),
                    NotificationPayload(title: "\(a) years",
                                        body: "\(weeksLived) weeks used. \(weeksRemaining) remain."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "Another year consumed.",
                                        body: "\(a) years gone. \(yearsLeft) remain."),
                    NotificationPayload(title: "Year \(a).",
                                        body: "Each birthday is 52 more weeks ticked off."),
                    NotificationPayload(title: "\(a) years old.",
                                        body: "\(weeksLived) squares filled. How many mattered?"),
                ]
            }

        // ── New Year ────────────────────────────────────────────────────
        case .newYear:
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "New year",
                                        body: "A fresh set of 52 weeks just opened."),
                    NotificationPayload(title: "Year begins",
                                        body: "52 new weeks. What will you fill them with?"),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "New year. Fewer weeks.",
                                        body: "The calendar resets. Your countdown doesn't."),
                    NotificationPayload(title: "Year starts now",
                                        body: "52 weeks to spend. Spend them wisely."),
                    NotificationPayload(title: "New year",
                                        body: "\(weeksRemaining) weeks remain. Make this one count."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "New year. Same clock.",
                                        body: "The year changes. Your countdown doesn't."),
                    NotificationPayload(title: "New year.",
                                        body: "\(weeksRemaining) weeks left. The number just shrank."),
                    NotificationPayload(title: "Year reset.",
                                        body: "Time doesn't reset with it."),
                ]
            }

        // ── Month start ─────────────────────────────────────────────────
        case .monthStart:
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "New month",
                                        body: "A few more weeks just opened up for you."),
                    NotificationPayload(title: "Month begins",
                                        body: "What will these ~4 weeks mean?"),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "New month",
                                        body: "~4 weeks. How will you fill them?"),
                    NotificationPayload(title: "Month starts",
                                        body: "~4 weeks. 28 days. 672 hours. Use them."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "Another month.",
                                        body: "\(weeksRemaining) weeks remain. One month closer."),
                    NotificationPayload(title: "Month begins.",
                                        body: "Time doesn't wait for the month to be ready."),
                ]
            }

        // ── Milestone ───────────────────────────────────────────────────
        case .milestone(let fraction, _):
            let pctStr = "\(Int(fraction * 100))%"
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "Milestone reached",
                                        body: "You've lived \(pctStr) of your expected life."),
                    NotificationPayload(title: "\(pctStr) of your life",
                                        body: "\(weeksLived) weeks lived. Still going."),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "You've crossed \(pctStr)",
                                        body: "\(weeksRemaining) weeks still ahead of you."),
                    NotificationPayload(title: "\(pctStr) milestone",
                                        body: "At \(age), you've lived \(weeksLived) weeks."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "\(pctStr) of your life: gone.",
                                        body: "\(weeksRemaining) weeks remain. Use them."),
                    NotificationPayload(title: "Halfway.",
                                        body: "More life is behind you now than ahead."),
                    NotificationPayload(title: "\(pctStr) done.",
                                        body: "The clock doesn't stop for reflection."),
                ]
            }

        // ── Entering new decade ─────────────────────────────────────────
        case .enteringDecade(let a):
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "A new decade",
                                        body: "Welcome to your \(a)s. A whole new chapter."),
                    NotificationPayload(title: "You're \(a)",
                                        body: "New decade, new weeks ahead."),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "You just turned \(a)",
                                        body: "A decade begins. What will define it?"),
                    NotificationPayload(title: "Decade \(a / 10)",
                                        body: "Your \(a)s start now. Make them count."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "A decade just ended.",
                                        body: "\(a) years gone. How many decades remain?"),
                    NotificationPayload(title: "You're \(a) now.",
                                        body: "Each decade narrows the ones still ahead."),
                    NotificationPayload(title: "Decade closed.",
                                        body: "\(a) years down. \(yearsLeft) left."),
                ]
            }

        // ── Weekly reflection ───────────────────────────────────────────
        case .weeklyReflection:
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "Week \(weeksLived)",
                                        body: "Another week of your life just passed."),
                    NotificationPayload(title: "This week",
                                        body: "What did this week mean to you?"),
                    NotificationPayload(title: "Week gone",
                                        body: "One more week lived. You're still here."),
                    NotificationPayload(title: "Reflect",
                                        body: "Another week behind you. How was it spent?"),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "Week \(weeksLived) done",
                                        body: "~\(weeksRemaining) weeks left. Make them count."),
                    NotificationPayload(title: "Week lived",
                                        body: "This week is gone. Next week is still yours."),
                    NotificationPayload(title: "Weekly check-in",
                                        body: "At \(age), you've lived \(weeksLived) weeks."),
                    NotificationPayload(title: "\(p)% lived",
                                        body: "\(weeksRemaining) weeks still ahead. Open your grid."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "Week \(weeksLived): gone.",
                                        body: "\(weeksRemaining) remain. Weeks don't come back."),
                    NotificationPayload(title: "Another week consumed.",
                                        body: "Time is quietly moving forward."),
                    NotificationPayload(title: "Week passed.",
                                        body: "You'll never live week \(weeksLived) again."),
                    NotificationPayload(title: "\(weeksRemaining) weeks left.",
                                        body: "That number just got one smaller."),
                ]
            }

        // ── Awareness ───────────────────────────────────────────────────
        case .awareness:
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "Life in weeks",
                                        body: "You've lived \(weeksLived) weeks so far."),
                    NotificationPayload(title: "Your life",
                                        body: "~\(yearsLeft) years of weeks still ahead of you."),
                    NotificationPayload(title: "Weeks lived",
                                        body: "\(weeksLived) squares filled. More to come."),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "\(p)% of your life",
                                        body: "\(weeksLived) weeks lived. \(weeksRemaining) ahead."),
                    NotificationPayload(title: "Life in numbers",
                                        body: "At \(age), you've used \(p)% of your weeks."),
                    NotificationPayload(title: "Your grid",
                                        body: "\(weeksLived) past. \(weeksRemaining) future. Now: this week."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "\(weeksLived) weeks gone.",
                                        body: "\(weeksRemaining) remain. Open your grid."),
                    NotificationPayload(title: "\(p)% lived.",
                                        body: "The rest is still up to you."),
                    NotificationPayload(title: "Your weeks.",
                                        body: "Each square is a week you'll never get back."),
                ]
            }

        // ── Urgency ─────────────────────────────────────────────────────
        case .urgency:
            switch tone {
            case .gentle:
                return [
                    NotificationPayload(title: "This week is still yours",
                                        body: "Make something of it."),
                    NotificationPayload(title: "A reminder",
                                        body: "Time moves forward. So can you."),
                    NotificationPayload(title: "Just a nudge",
                                        body: "This week is still open. Use it."),
                ]
            case .balanced:
                return [
                    NotificationPayload(title: "Weeks don't wait",
                                        body: "This one is passing right now."),
                    NotificationPayload(title: "Make this week count",
                                        body: "\(weeksRemaining) left. Start with this one."),
                    NotificationPayload(title: "Time is moving",
                                        body: "Quietly, steadily. Are you moving with it?"),
                    // Viral: makes user open immediately
                    NotificationPayload(title: "Your life grid changed.",
                                        body: "Another week filled in. Come see it."),
                ]
            case .deep:
                return [
                    NotificationPayload(title: "Time doesn't slow down.",
                                        body: "You have to."),
                    NotificationPayload(title: "Weeks don't wait.",
                                        body: "\(weeksRemaining) left. This one is already leaving."),
                    NotificationPayload(title: "The clock is running.",
                                        body: "\(weeksRemaining) weeks. Each one matters."),
                    // Viral: impossible to ignore
                    NotificationPayload(title: "Week \(weeksLived) of \(weeksLived + weeksRemaining).",
                                        body: "Tap to see where you are."),
                ]
            }
        }
    }
}
