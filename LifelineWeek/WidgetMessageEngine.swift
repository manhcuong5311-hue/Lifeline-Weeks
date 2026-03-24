import Foundation

// MARK: - Message model

struct WidgetMessage {
    let id:   String
    let text: String   // final text, no placeholders
}

// MARK: - Engine

enum WidgetMessageEngine {

    // MARK: - Public

    static func generate(stats: WidgetStats, recentIDs: [String]) -> WidgetMessage {
        let pool     = buildPool(stats: stats)
        let filtered = pool.filter { !recentIDs.contains($0.id) }
        // Fall back to full pool if filtered is empty; fall back to sentinel if pool is empty
        let source   = filtered.isEmpty ? pool : filtered
        guard !source.isEmpty else {
            return WidgetMessage(id: "fallback", text: "\(stats.weeksLived) weeks lived.\nMake this one count.")
        }

        // Deterministic rotation: varies by days lived AND day of week
        let dayOfWeek = Calendar.current.component(.weekday, from: Date())
        let idx       = (stats.daysLived + dayOfWeek * 3) % source.count
        return source[idx]
    }

    // MARK: - Pool builder

    private static func buildPool(stats: WidgetStats) -> [WidgetMessage] {
        let wl  = stats.weeksLivedFormatted       // "1,560"
        let wr  = stats.weeksRemainingFormatted   // "2,860"
        let tot = stats.totalWeeksFormatted       // "4,420"
        let p   = stats.progressPercent           // 37
        let yr  = stats.yearsRemaining            // 54
        let day = Calendar.current.component(.weekday, from: Date())  // 1=Sun … 7=Sat

        var pool: [WidgetMessage] = []

        // ── Monday: fresh-start energy ──────────────────────────────────
        if day == 2 {
            pool += monday(wl: wl, wr: wr)
        }

        // ── Wednesday / Thursday: midweek awareness ──────────────────────
        if day == 4 || day == 5 {
            pool += midweek(wl: wl, wr: wr, tot: tot, p: p)
        }

        // ── Sunday: reflection ───────────────────────────────────────────
        if day == 1 {
            pool += sunday(wl: wl, wr: wr, p: p)
        }

        // ── Progress-based (always included) ─────────────────────────────
        switch stats.progress {
        case ..<0.20:       pool += earlyLife(wr: wr, p: p, yr: yr)
        case 0.20..<0.50:   pool += buildingLife(wl: wl, wr: wr, p: p)
        case 0.50..<0.75:   pool += urgentLife(wr: wr, p: p)
        default:            pool += deepAwareness(wr: wr, p: p, yr: yr)
        }

        // ── Evergreen (always included) ──────────────────────────────────
        pool += evergreen(wl: wl, wr: wr, tot: tot, p: p)

        return pool
    }

    // MARK: - Message categories

    // 8 Monday messages
    private static func monday(wl: String, wr: String) -> [WidgetMessage] { [
        WidgetMessage(id: "m01", text: "Week starts now.\nWhat will you do with it?"),
        WidgetMessage(id: "m02", text: "Fresh week.\n\(wr) still ahead of you."),
        WidgetMessage(id: "m03", text: "Monday again.\nOne less week in the bank."),
        WidgetMessage(id: "m04", text: "\(wl) weeks lived.\nThis one just opened."),
        WidgetMessage(id: "m05", text: "New week.\nMake this one count."),
        WidgetMessage(id: "m06", text: "The week is blank.\nYou decide what goes in it."),
        WidgetMessage(id: "m07", text: "Another week.\nAnother chance."),
        WidgetMessage(id: "m08", text: "Week \(wl) begins.\nUse it."),
    ] }

    // 6 midweek messages
    private static func midweek(wl: String, wr: String, tot: String, p: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "w01", text: "Midweek.\nAre you spending it well?"),
        WidgetMessage(id: "w02", text: "\(wr) weeks remain.\nThis is one of them."),
        WidgetMessage(id: "w03", text: "\(p)% lived.\nStill here."),
        WidgetMessage(id: "w04", text: "You're in week \(wl)\nof \(tot)."),
        WidgetMessage(id: "w05", text: "The week is half gone.\nMake the rest count."),
        WidgetMessage(id: "w06", text: "\(wl) weeks behind you.\n\(wr) ahead."),
    ] }

    // 8 Sunday reflection messages
    private static func sunday(wl: String, wr: String, p: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "s01", text: "Week \(wl) is almost done.\nHow did you spend it?"),
        WidgetMessage(id: "s02", text: "Sunday.\n\(wr) weeks left."),
        WidgetMessage(id: "s03", text: "Another week closes.\nDid it matter?"),
        WidgetMessage(id: "s04", text: "This week is nearly over.\nWas it worth it?"),
        WidgetMessage(id: "s05", text: "\(p)% of your life lived.\nReflect."),
        WidgetMessage(id: "s06", text: "End of week \(wl).\n\(wr) remain."),
        WidgetMessage(id: "s07", text: "Sunday.\nAnother square filled in."),
        WidgetMessage(id: "s08", text: "Week gone.\nWhat will you do with the next one?"),
    ] }

    // 8 early life messages (< 20%)
    private static func earlyLife(wr: String, p: Int, yr: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "e01", text: "The story is just beginning.\n\(wr) weeks ahead."),
        WidgetMessage(id: "e02", text: "Most of your life is ahead.\nUse it wisely."),
        WidgetMessage(id: "e03", text: "\(p)% done.\nThe rest is still yours."),
        WidgetMessage(id: "e04", text: "~\(yr) years ahead of you.\nMake them real."),
        WidgetMessage(id: "e05", text: "\(wr) weeks.\nAll still unwritten."),
        WidgetMessage(id: "e06", text: "Your life is mostly future.\nDecide what it looks like."),
        WidgetMessage(id: "e07", text: "\(p)% lived.\nThe canvas is open."),
        WidgetMessage(id: "e08", text: "Still so much ahead.\nStart something that matters."),
    ] }

    // 8 building life messages (20–50%)
    private static func buildingLife(wl: String, wr: String, p: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "b01", text: "You're building your life now.\nBuild well."),
        WidgetMessage(id: "b02", text: "\(p)% behind you.\n\(100 - p)% still ahead."),
        WidgetMessage(id: "b03", text: "The middle chapters define you.\nWrite them carefully."),
        WidgetMessage(id: "b04", text: "\(wl) weeks lived.\nThe work continues."),
        WidgetMessage(id: "b05", text: "In the thick of it.\n\(wr) weeks left."),
        WidgetMessage(id: "b06", text: "Building years.\nWhat are you building?"),
        WidgetMessage(id: "b07", text: "\(p)% done.\nThe foundation is still being set."),
        WidgetMessage(id: "b08", text: "\(wl) weeks behind.\n\(wr) to use wisely."),
    ] }

    // 8 urgency messages (50–75%)
    private static func urgentLife(wr: String, p: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "u01", text: "More life behind than ahead.\nMake it count."),
        WidgetMessage(id: "u02", text: "\(p)% lived.\n\(wr) weeks remain."),
        WidgetMessage(id: "u03", text: "The second half is here.\nUse it differently."),
        WidgetMessage(id: "u04", text: "\(wr) weeks left.\nThe number is shrinking."),
        WidgetMessage(id: "u05", text: "Past halfway.\n\(wr) weeks to go."),
        WidgetMessage(id: "u06", text: "More weeks gone than coming.\nMake them matter."),
        WidgetMessage(id: "u07", text: "\(p)% done.\nThe rest is urgent."),
        WidgetMessage(id: "u08", text: "Time is finite.\n\(wr) weeks. Use them."),
    ] }

    // 8 deep awareness messages (75%+)
    private static func deepAwareness(wr: String, p: Int, yr: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "d01", text: "Most of your life is behind you.\nEvery week counts."),
        WidgetMessage(id: "d02", text: "\(wr) weeks remain.\nNone of them are spare."),
        WidgetMessage(id: "d03", text: "\(p)% lived.\nWhat will the rest be for?"),
        WidgetMessage(id: "d04", text: "The final chapters.\nWrite them well."),
        WidgetMessage(id: "d05", text: "\(wr) weeks. ~\(yr) years.\nBe deliberate."),
        WidgetMessage(id: "d06", text: "Late in the journey.\nWhat still matters most?"),
        WidgetMessage(id: "d07", text: "The time that remains is precious.\n\(wr) weeks."),
        WidgetMessage(id: "d08", text: "\(p)% done.\nMake the rest magnificent."),
    ] }

    // 15 evergreen messages (always in pool)
    private static func evergreen(wl: String, wr: String, tot: String, p: Int) -> [WidgetMessage] { [
        WidgetMessage(id: "g01", text: "\(wl) weeks lived.\n\(wr) ahead."),
        WidgetMessage(id: "g02", text: "\(wl) weeks.\nEach one a choice."),
        WidgetMessage(id: "g03", text: "Week \(wl) of \(tot).\nHere."),
        WidgetMessage(id: "g04", text: "\(p)% of your life.\nLived."),
        WidgetMessage(id: "g05", text: "This week is one of \(tot).\nMake it count."),
        WidgetMessage(id: "g06", text: "Time passes.\nAre you present in it?"),
        WidgetMessage(id: "g07", text: "Weeks don't wait.\nThis one is now."),
        WidgetMessage(id: "g08", text: "\(wl) squares filled.\n\(wr) remain."),
        WidgetMessage(id: "g09", text: "One week at a time.\nThis is that week."),
        WidgetMessage(id: "g10", text: "\(wl) lived.\n\(wr) left. Use this one."),
        WidgetMessage(id: "g11", text: "Each week is a choice.\nChoose this one well."),
        WidgetMessage(id: "g12", text: "Right now.\nThis is week \(wl)."),
        WidgetMessage(id: "g13", text: "\(wl) weeks of life.\nAll leading here."),
        WidgetMessage(id: "g14", text: "\(wr) more weeks.\nDon't waste this one."),
        WidgetMessage(id: "g15", text: "Life in weeks.\n\(p)% complete."),
    ] }
}
