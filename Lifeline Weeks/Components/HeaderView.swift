import SwiftUI

struct HeaderView: View {
    let progress:       Double
    let weeksLived:     Int
    let weeksRemaining: Int
    var userName:       String = ""
    var insight:        String = ""

    @EnvironmentObject private var themeManager: ThemeManager

    @State private var displayedProgress: Double = 0
    @State private var appeared = false

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.l) {

            // ── Greeting ──────────────────────────────────────────────────
            if !userName.isEmpty {
                Text("\(timeGreeting), \(userName).")
                    .font(.lifeBody)
                    .foregroundStyle(theme.textSecondary)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 8)
                    .animation(.easeOut(duration: 0.5).delay(0.0), value: appeared)
            }

            // ── Hero percentage ───────────────────────────────────────────
            VStack(alignment: .leading, spacing: 4) {
                Text("\(displayedPercent)%")
                    .font(.lifeHero)
                    .foregroundStyle(theme.accentDiagonal)
                    .contentTransition(.numericText())
                    .animation(.easeInOut(duration: 0.7), value: displayedPercent)

                Text("of life lived")
                    .font(.lifeSubhead)
                    .foregroundStyle(theme.textSecondary)
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 12)
            .animation(.easeOut(duration: 0.55).delay(0.05), value: appeared)

            // ── Remaining ─────────────────────────────────────────────────
            Text("\(100 - displayedPercent)% still ahead of you")
                .font(.lifeBody)
                .foregroundStyle(theme.textTertiary)
                .contentTransition(.numericText())
                .animation(.easeInOut(duration: 0.7), value: displayedPercent)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 10)
                .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)

            // ── Stats row (glass card) ────────────────────────────────────
            HStack(spacing: 0) {
                statLabel(value: weeksLived, title: "Weeks lived")
                    .frame(maxWidth: .infinity)

                Divider()
                    .frame(height: 32)
                    .background(theme.divider)

                statLabel(value: weeksRemaining, title: "Weeks left")
                    .frame(maxWidth: .infinity)
            }
            .padding(.vertical, DS.Spacing.m)
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .strokeBorder(theme.divider, lineWidth: 1)
            )
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 8)
            .animation(.easeOut(duration: 0.5).delay(0.15), value: appeared)

            // ── Insight / emotional label ─────────────────────────────────
            Group {
                if !insight.isEmpty {
                    Text(insight)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                } else {
                    Text(emotionalLabel)
                }
            }
            .font(.lifeCaption)
            .foregroundStyle(theme.textTertiary)
            .italic()
            .opacity(appeared ? 1 : 0)
            .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.Spacing.l)
        .padding(.top, DS.Spacing.l)
        .padding(.bottom, DS.Spacing.m)
        .onAppear {
            appeared = true
            withAnimation(.easeInOut(duration: 0.9).delay(0.2)) {
                displayedProgress = progress
            }
        }
        .onChange(of: progress) { _, newValue in
            withAnimation(.easeInOut(duration: 0.7)) {
                displayedProgress = newValue
            }
        }
    }

    // MARK: - Sub-views

    private func statLabel(value: Int, title: String) -> some View {
        VStack(alignment: .center, spacing: 3) {
            Text("\(value)")
                .font(.lifeStat)
                .foregroundStyle(theme.textPrimary)
                .contentTransition(.numericText())
            Text(title)
                .font(.lifeLabel)
                .foregroundStyle(theme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.8)
        }
    }

    // MARK: - Helpers

    private var displayedPercent: Int { Int((displayedProgress * 100).rounded()) }

    private var timeGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 0..<12:  return "Good morning"
        case 12..<18: return "Good afternoon"
        default:      return "Good evening"
        }
    }

    private var emotionalLabel: String {
        switch progress {
        case ..<0.20:      return "The best chapters are still unwritten."
        case 0.20..<0.50:  return "You are in the thick of it. Build wisely."
        case 0.50..<0.75:  return "More has passed than remains. Use it well."
        default:           return "Every week from here is borrowed time."
        }
    }
}

#Preview {
    ZStack {
        LinearGradient.appBackground.ignoresSafeArea()
        HeaderView(progress: 0.38, weeksLived: 1560, weeksRemaining: 2600,
                   insight: "You've lived more than 1/3 of your life")
            .padding()
    }
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}
