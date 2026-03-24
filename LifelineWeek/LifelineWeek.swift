import WidgetKit
import SwiftUI

// MARK: - Entry

struct LifeWidgetEntry: TimelineEntry {
    let date:           Date
    let progress:       Double
    let weeksLived:     Int
    let weeksRemaining: Int
    let daysLived:      Int
    let daysRemaining:  Int
    let message:        String
    let isConfigured:   Bool

    var progressPercent: Int { Int((progress * 100).rounded()) }

    // Placeholder for Xcode canvas previews
    static let placeholder = LifeWidgetEntry(
        date:           Date(),
        progress:       0.38,
        weeksLived:     1560,
        weeksRemaining: 2540,
        daysLived:      10920,
        daysRemaining:  17780,
        message:        "1,560 weeks lived.\nMake this one count.",
        isConfigured:   true
    )

    static let unconfigured = LifeWidgetEntry(
        date:           Date(),
        progress:       0,
        weeksLived:     0,
        weeksRemaining: 0,
        daysLived:      0,
        daysRemaining:  0,
        message:        "Open Life in Weeks\nto get started.",
        isConfigured:   false
    )
}

// MARK: - Timeline provider

struct LifeTimelineProvider: TimelineProvider {

    func placeholder(in context: Context) -> LifeWidgetEntry {
        .placeholder
    }

    func getSnapshot(in context: Context, completion: @escaping (LifeWidgetEntry) -> Void) {
        completion(context.isPreview ? .placeholder : buildEntry())
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<LifeWidgetEntry>) -> Void) {
        let entry = buildEntry()

        // Refresh at next midnight — data changes once per day
        let tomorrow   = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        let nextUpdate = Calendar.current.startOfDay(for: tomorrow)

        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    // MARK: - Entry construction

    private func buildEntry() -> LifeWidgetEntry {
        guard let profile = WidgetDataStore.loadProfile() else {
            return .unconfigured
        }

        let stats   = WidgetDataStore.computeStats(
            birthDate:       profile.birthDate,
            lifeExpectancy:  profile.lifeExpectancy
        )
        let message = WidgetMessageEngine.generate(
            stats:      stats,
            recentIDs:  WidgetDataStore.recentMessageIDs
        )
        WidgetDataStore.recordShown(message.id)

        return LifeWidgetEntry(
            date:           Date(),
            progress:       stats.progress,
            weeksLived:     stats.weeksLived,
            weeksRemaining: stats.weeksRemaining,
            daysLived:      stats.daysLived,
            daysRemaining:  stats.daysRemaining,
            message:        message.text,
            isConfigured:   true
        )
    }
}

// MARK: - Entry view (dispatches by family)

struct LifeWidgetEntryView: View {
    let entry: LifeWidgetEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        Group {
            switch family {
            case .systemSmall:            SmallWidgetView(entry: entry)
            case .systemMedium:           MediumWidgetView(entry: entry)
            case .accessoryCircular:      AccessoryCircularView(entry: entry)
            case .accessoryRectangular:   AccessoryRectangularView(entry: entry)
            case .accessoryInline:        AccessoryInlineView(entry: entry)
            default:                      SmallWidgetView(entry: entry)
            }
        }
        .containerBackground(for: .widget) {
            switch family {
            case .systemSmall, .systemMedium, .systemLarge, .systemExtraLarge:
                WDS.background
            default:
                AccessoryWidgetBackground()
            }
        }
    }
}

// MARK: - Small widget (169 × 169 pts)

struct SmallWidgetView: View {
    let entry: LifeWidgetEntry

    var body: some View {
        if !entry.isConfigured {
            setupPrompt
        } else {
            VStack(alignment: .leading, spacing: 0) {

                // ── Big % hero ──────────────────────────────────────
                Text("\(entry.progressPercent)%")
                    .font(.system(size: 44, weight: .bold, design: .rounded))
                    .foregroundStyle(WDS.accentGradient)
                    .minimumScaleFactor(0.7)

                Text("of life lived")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(WDS.textSecondary)
                    .padding(.top, 1)

                Spacer(minLength: 8)

                // ── Message ─────────────────────────────────────────
                Text(entry.message)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(WDS.textPrimary)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: 8)

                // ── Weeks remaining ──────────────────────────────────
                HStack(alignment: .firstTextBaseline, spacing: 3) {
                    Text(entry.weeksRemaining.formatted(.number))
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(WDS.textPrimary)
                    Text("weeks left")
                        .font(.system(size: 10, design: .rounded))
                        .foregroundStyle(WDS.textTertiary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(14)
        }
    }

    private var setupPrompt: some View {
        VStack(spacing: 6) {
            Image(systemName: "square.grid.3x3.fill")
                .font(.system(size: 24))
                .foregroundStyle(WDS.textTertiary)
            Text("Open app\nto set up")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(WDS.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Medium widget (360 × 169 pts)

struct MediumWidgetView: View {
    let entry: LifeWidgetEntry

    var body: some View {
        HStack(spacing: 0) {

            // ── Left panel: stats ────────────────────────────────────
            VStack(alignment: .leading, spacing: 10) {

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(entry.progressPercent)%")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundStyle(WDS.accentGradient)
                        .minimumScaleFactor(0.7)

                    Text("of life lived")
                        .font(.system(size: 9, weight: .medium, design: .rounded))
                        .foregroundStyle(WDS.textSecondary)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }

                HStack(spacing: 14) {
                    statItem(value: entry.weeksLived.formatted(.number),     label: "lived")
                    statItem(value: entry.weeksRemaining.formatted(.number), label: "ahead")
                }

                Spacer(minLength: 0)

                // Days lived (subtle tertiary)
                Text("\(entry.daysLived.formatted(.number)) days in")
                    .font(.system(size: 9, design: .rounded))
                    .foregroundStyle(WDS.textTertiary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // ── Divider ──────────────────────────────────────────────
            Rectangle()
                .fill(WDS.divider)
                .frame(width: 1)
                .padding(.vertical, 4)
                .padding(.horizontal, 12)

            // ── Right panel: message + progress bar ──────────────────
            VStack(alignment: .leading, spacing: 0) {

                Text(entry.message)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(WDS.textPrimary)
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 10)

                // Progress bar
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(WDS.divider)
                            .frame(height: 3)
                        RoundedRectangle(cornerRadius: 2, style: .continuous)
                            .fill(WDS.accentGradient)
                            .frame(width: geo.size.width * CGFloat(entry.progress), height: 3)
                    }
                }
                .frame(height: 3)

                Text("\(entry.progressPercent)% complete")
                    .font(.system(size: 8, design: .rounded))
                    .foregroundStyle(WDS.textTertiary)
                    .padding(.top, 3)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(14)
    }

    private func statItem(value: String, label: String) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(value)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(WDS.textPrimary)
            Text("wks \(label)")
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(WDS.textTertiary)
                .textCase(.uppercase)
                .tracking(0.3)
        }
    }
}

// MARK: - Accessory Circular (lock screen)

struct AccessoryCircularView: View {
    let entry: LifeWidgetEntry

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: 1) {
                Text("\(entry.progressPercent)%")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.8)
                Text("\(entry.weeksRemaining / 52)yr")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Accessory Rectangular (lock screen banner)

struct AccessoryRectangularView: View {
    let entry: LifeWidgetEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 5) {
                Text("\(entry.progressPercent)%")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                Text("·")
                    .foregroundStyle(.secondary)
                Text("\(entry.weeksRemaining.formatted(.number)) weeks left")
                    .font(.system(size: 11, design: .rounded))
            }
            Text(firstLine(of: entry.message))
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func firstLine(of text: String) -> String {
        text.components(separatedBy: "\n").first ?? text
    }
}

// MARK: - Accessory Inline (lock screen, single line)

struct AccessoryInlineView: View {
    let entry: LifeWidgetEntry

    var body: some View {
        Text("\(entry.progressPercent)% · \(entry.weeksRemaining.formatted(.number)) weeks left")
    }
}

// MARK: - Widget definition

struct LifelineWeek: Widget {
    let kind = "LifelineWeek"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: LifeTimelineProvider()) { entry in
            LifeWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Life in Weeks")
        .description("Your life, week by week.")
        .supportedFamilies([
            .systemSmall,
            .systemMedium,
            .accessoryCircular,
            .accessoryRectangular,
            .accessoryInline,
        ])
    }
}

// MARK: - Widget Design System (self-contained, mirrors main app DS values)

private enum WDS {
    static let background    = Color(red: 0.051, green: 0.051, blue: 0.059)   // #0D0D0F
    static let textPrimary   = Color(white: 0.94)
    static let textSecondary = Color(white: 0.94).opacity(0.55)
    static let textTertiary  = Color(white: 0.94).opacity(0.32)
    static let divider       = Color(white: 1.0).opacity(0.08)
    static let accentBlue    = Color(red: 0.47, green: 0.65, blue: 1.00)
    static let accentPurple  = Color(red: 0.72, green: 0.52, blue: 1.00)

    static let accentGradient = LinearGradient(
        colors: [accentBlue, accentPurple],
        startPoint: .leading,
        endPoint: .trailing
    )
}

// MARK: - Previews

#Preview(as: .systemSmall) {
    LifelineWeek()
} timeline: {
    LifeWidgetEntry.placeholder
    LifeWidgetEntry.unconfigured
}

#Preview(as: .systemMedium) {
    LifelineWeek()
} timeline: {
    LifeWidgetEntry.placeholder
}

#Preview(as: .accessoryCircular) {
    LifelineWeek()
} timeline: {
    LifeWidgetEntry.placeholder
}

#Preview(as: .accessoryRectangular) {
    LifelineWeek()
} timeline: {
    LifeWidgetEntry.placeholder
}

#Preview(as: .accessoryInline) {
    LifelineWeek()
} timeline: {
    LifeWidgetEntry.placeholder
}
