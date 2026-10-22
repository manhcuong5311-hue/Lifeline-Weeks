import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var viewModel:     LifeViewModel
    @EnvironmentObject private var themeManager:  ThemeManager
    @ObservedObject private var adFree = AdFreeStatus.shared
    @ObservedObject private var ads    = AdsManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var birthDate              = Date()
    @State private var lifeExpectancy         = 90
    @State private var showRemoveAds           = false
    @State private var showResetConfirm        = false
    @State private var showNotificationPreview = false
    @State private var showFAQ                 = false
    @State private var showWidgetGuide         = false

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: DS.Spacing.xl) {
                profileCard
                appearanceSection
                lifeSection
                notificationsSection
                removeAdsSection
                aboutSection
                resetSection
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.top, DS.Spacing.l)
            .padding(.bottom, DS.Spacing.xxl)
        }
        .background(theme.background.ignoresSafeArea())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(theme.background.opacity(0.95), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .onAppear {
            birthDate      = viewModel.birthDate
            lifeExpectancy = viewModel.lifeExpectancy
        }
        .sheet(isPresented: $showRemoveAds) { RemoveAdsSheet() }
        .sheet(isPresented: $showWidgetGuide) { WidgetGuideView() }
        .sheet(isPresented: $showFAQ) {
            FAQView(theme: theme)
        }
        .sheet(isPresented: $showNotificationPreview) {
            NotificationPreviewSheet(
                tone:           viewModel.notificationTone,
                weeksLived:     viewModel.weeksLived,
                weeksRemaining: viewModel.weeksRemaining
            )
        }
        .confirmationDialog(
            "This will erase your profile and return to onboarding.",
            isPresented: $showResetConfirm,
            titleVisibility: .visible
        ) {
            Button("Reset", role: .destructive) { reset() }
        }
    }

    // MARK: - Profile card

    private var profileCard: some View {
        VStack(spacing: DS.Spacing.m) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Life")
                        .font(.lifeSubhead)
                        .foregroundStyle(theme.textPrimary)
                    Text(ageDescription)
                        .font(.lifeCaption)
                        .foregroundStyle(theme.textSecondary)
                }
                Spacer()
                ZStack {
                    Circle()
                        .fill(theme.accentGradient)
                        .frame(width: 44, height: 44)
                    Image(systemName: "person.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
            }

            Divider().background(theme.divider)

            HStack(spacing: 0) {
                statPill(
                    value: "\(viewModel.weeksLived)",
                    label: "Weeks lived"
                )
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 1, height: 36)

                statPill(
                    value: "\(viewModel.weeksRemaining)",
                    label: "Weeks ahead"
                )
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(theme.divider)
                    .frame(width: 1, height: 36)

                statPill(
                    value: "\(Int((viewModel.progress * 100).rounded()))%",
                    label: "Complete"
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(DS.Spacing.l)
        .settingsCard(theme: theme)
    }

    private func statPill(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.lifeStat)
                .foregroundStyle(theme.textPrimary)
            Text(label)
                .font(.lifeLabel)
                .foregroundStyle(theme.textTertiary)
                .textCase(.uppercase)
                .tracking(0.5)
        }
    }

    // MARK: - Appearance section

    private var appearanceSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader("Appearance")

            VStack(spacing: DS.Spacing.m) {
                // Theme swatches
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    settingsRowLabel("Theme")

                    LazyVGrid(
                        columns: Array(repeating: GridItem(.flexible(), spacing: DS.Spacing.s), count: 3),
                        spacing: DS.Spacing.s
                    ) {
                        ForEach(AppThemeStyle.allCases) { style in
                            ThemeSwatchCell(
                                style:       style,
                                isSelected:  themeManager.themeStyle == style,
                                onTap:       { themeManager.setTheme(style) }
                            )
                        }
                    }
                }

                Divider().background(theme.divider)

                // Grid style picker
                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    settingsRowLabel("Grid Style")

                    HStack(spacing: DS.Spacing.s) {
                        ForEach(GridStyle.allCases) { style in
                            GridStyleCell(
                                style:      style,
                                isSelected: themeManager.gridStyle == style,
                                theme:      theme,
                                onTap: { themeManager.gridStyle = style }
                            )
                            .frame(maxWidth: .infinity)
                        }
                    }
                }
            }
            .padding(DS.Spacing.l)
            .settingsCard(theme: theme)
        }
    }

    // MARK: - Life section

    private var lifeSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader("Life Settings")

            VStack(spacing: 0) {
                // Birthday
                HStack {
                    Label("Birthday", systemImage: "birthday.cake")
                        .font(.lifeBody)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    DatePicker(
                        "",
                        selection: $birthDate,
                        in: UserProfile.earliestBirth...Date(),
                        displayedComponents: .date
                    )
                    .labelsHidden()
                    .colorScheme(theme.colorScheme == .light ? .light : .dark)
                    .onChange(of: birthDate) { _, new in viewModel.birthDate = new }
                }
                .padding(DS.Spacing.l)

                Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                // Life expectancy
                VStack(spacing: DS.Spacing.s) {
                    HStack {
                        Label("Life expectancy", systemImage: "heart.fill")
                            .font(.lifeBody)
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Text("\(lifeExpectancy) years")
                            .font(.lifeBody)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.accentBlue)
                    }
                    Slider(value: expectancyBinding, in: 50...120, step: 1)
                        .tint(theme.accentBlue)
                        .onChange(of: lifeExpectancy) { _, new in
                            viewModel.lifeExpectancy = new
                        }
                }
                .padding(DS.Spacing.l)
            }
            .settingsCard(theme: theme)
        }
    }

    // MARK: - Notifications section

    private var notificationsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader("Notifications")

            VStack(spacing: 0) {
                // Toggle
                HStack {
                    Label("Weekly reminder", systemImage: "bell.fill")
                        .font(.lifeBody)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Toggle("", isOn: $viewModel.notificationsEnabled)
                        .labelsHidden()
                        .tint(theme.accentBlue)
                }
                .padding(DS.Spacing.l)

                if viewModel.notificationsEnabled {
                    Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                    // Day picker
                    HStack {
                        Text("Day")
                            .font(.lifeBody)
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Picker("", selection: $viewModel.notificationSchedule.weekday) {
                            ForEach(1...7, id: \.self) { day in
                                Text(weekdayName(day)).tag(day)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(theme.accentBlue)
                    }
                    .padding(DS.Spacing.l)

                    Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                    // Time picker
                    HStack {
                        Text("Time")
                            .font(.lifeBody)
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        DatePicker(
                            "",
                            selection: scheduleTimeBinding,
                            displayedComponents: .hourAndMinute
                        )
                        .labelsHidden()
                        .colorScheme(theme.colorScheme == .light ? .light : .dark)
                        .frame(width: 100)
                    }
                    .padding(DS.Spacing.l)

                    Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                    // Tone picker
                    VStack(spacing: DS.Spacing.s) {
                        HStack {
                            Text("Tone")
                                .font(.lifeBody)
                                .foregroundStyle(theme.textPrimary)
                            Spacer()
                            Picker("", selection: $viewModel.notificationTone) {
                                ForEach(NotificationTone.allCases) { t in
                                    Text(t.rawValue).tag(t)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(theme.accentBlue)
                        }

                        HStack {
                            Text(viewModel.notificationTone.tagline)
                                .font(.lifeCaption)
                                .foregroundStyle(theme.textTertiary)
                            Spacer()
                            Button("Preview") { showNotificationPreview = true }
                                .font(.lifeCaption)
                                .foregroundStyle(theme.accentBlue)
                        }
                    }
                    .padding(DS.Spacing.l)
                }
            }
            .settingsCard(theme: theme)
        }
    }

    // MARK: - Remove Ads section

    private var removeAdsSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader("Ads")

            Button { showRemoveAds = true } label: {
                HStack(spacing: DS.Spacing.m) {
                    ZStack {
                        RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                            .fill(theme.accentGradient)
                            .frame(width: 40, height: 40)
                        Image(systemName: adFree.isAdFree ? "checkmark.seal.fill" : "nosign")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(adFree.isAdFree ? "Ad-free" : "Remove Ads")
                            .font(.lifeSubhead)
                            .foregroundStyle(theme.textPrimary)
                        Text(adFree.isAdFree ? "Thanks for supporting Lifeline Weeks"
                                             : "One-time purchase · no subscription")
                            .font(.lifeCaption)
                            .foregroundStyle(theme.textSecondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(theme.textTertiary)
                }
                .padding(DS.Spacing.l)
                .settingsCard(theme: theme)
            }
            .buttonStyle(.plain)

            // EEA/UK users must be able to revisit their ad consent.
            if ads.privacyOptionsRequired && !adFree.isAdFree {
                Button { ads.presentPrivacyOptions() } label: {
                    HStack(spacing: DS.Spacing.m) {
                        Image(systemName: "hand.raised.fill")
                            .foregroundStyle(theme.textSecondary)
                        Text("Ad privacy choices")
                            .font(.lifeSubhead)
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(DS.Spacing.l)
                    .settingsCard(theme: theme)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - About section

    private var aboutSection: some View {
        VStack(alignment: .leading, spacing: DS.Spacing.m) {
            sectionHeader("About")

            VStack(spacing: 0) {
                // Widget guide
                Button { showWidgetGuide = true } label: {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(
                                    LinearGradient(
                                        colors: [Color(red: 0.47, green: 0.65, blue: 1.00),
                                                 Color(red: 0.55, green: 0.45, blue: 1.00)],
                                        startPoint: .topLeading, endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 32, height: 32)
                            Image(systemName: "rectangle.3.group.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("How to Add Widget")
                                .font(.lifeBody)
                                .foregroundStyle(theme.textPrimary)
                            Text("Step-by-step guide")
                                .font(.lifeCaption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .padding(.leading, 4)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(DS.Spacing.l)
                }
                .buttonStyle(.plain)

                Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                settingsRow(icon: "info.circle", label: "Version", value: appVersion)

                Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                settingsRow(icon: "square.grid.3x3.fill", label: "App", value: "Life in Weeks")

                Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                Button { showFAQ = true } label: {
                    HStack {
                        Label("FAQ", systemImage: "questionmark.circle")
                            .font(.lifeBody)
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(DS.Spacing.l)
                }
                .buttonStyle(.plain)

                Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                Link(destination: AppConfig.reviewURL) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(Color(red: 1.00, green: 0.72, blue: 0.10))
                                .frame(width: 32, height: 32)
                            Image(systemName: "star.fill")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Rate Life in Weeks")
                                .font(.lifeBody)
                                .foregroundStyle(theme.textPrimary)
                            Text("Takes 10 seconds, means a lot ✨")
                                .font(.lifeCaption)
                                .foregroundStyle(theme.textSecondary)
                        }
                        .padding(.leading, 4)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(DS.Spacing.l)
                }

                Divider().background(theme.divider).padding(.leading, DS.Spacing.l)

                Link(destination: URL(string: "https://manhcuong5311-hue.github.io/Lifeline-Weeks/")!) {
                    HStack {
                        Label("Privacy Policy", systemImage: "hand.raised.fill")
                            .font(.lifeBody)
                            .foregroundStyle(theme.textPrimary)
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.textTertiary)
                    }
                    .padding(DS.Spacing.l)
                }
            }
            .settingsCard(theme: theme)
        }
    }

    private func settingsRow(icon: String, label: String, value: String) -> some View {
        HStack {
            Label(label, systemImage: icon)
                .font(.lifeBody)
                .foregroundStyle(theme.textPrimary)
            Spacer()
            Text(value)
                .font(.lifeBody)
                .foregroundStyle(theme.textSecondary)
        }
        .padding(DS.Spacing.l)
    }

    // MARK: - Reset section

    private var resetSection: some View {
        Button(role: .destructive) {
            showResetConfirm = true
        } label: {
            HStack {
                Spacer()
                Label("Reset & start over", systemImage: "arrow.counterclockwise")
                    .font(.lifeBody)
                    .foregroundStyle(Color.red.opacity(0.85))
                Spacer()
            }
            .padding(DS.Spacing.l)
            .settingsCard(theme: theme)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Helpers

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.lifeLabel)
            .foregroundStyle(theme.textTertiary)
            .tracking(1.0)
            .padding(.leading, DS.Spacing.xs)
    }

    private func settingsRowLabel(_ title: String) -> some View {
        Text(title)
            .font(.lifeBody)
            .foregroundStyle(theme.textSecondary)
    }

    private var scheduleTimeBinding: Binding<Date> {
        Binding(
            get: {
                var c = DateComponents()
                c.hour   = viewModel.notificationSchedule.hour
                c.minute = viewModel.notificationSchedule.minute
                return Calendar.current.date(from: c) ?? Date()
            },
            set: { date in
                let c = Calendar.current.dateComponents([.hour, .minute], from: date)
                viewModel.notificationSchedule.hour   = c.hour   ?? 9
                viewModel.notificationSchedule.minute = c.minute ?? 0
            }
        )
    }

    private var expectancyBinding: Binding<Double> {
        Binding(
            get: { Double(lifeExpectancy) },
            set: { lifeExpectancy = Int($0.rounded()) }
        )
    }

    private func weekdayName(_ n: Int) -> String {
        Calendar.current.weekdaySymbols[safe: n - 1] ?? "Day \(n)"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "—"
    }

    private var ageDescription: String {
        let components = Calendar.current.dateComponents([.year, .month], from: viewModel.birthDate, to: Date())
        let years  = components.year  ?? 0
        let months = components.month ?? 0
        return "\(years) years, \(months) months old"
    }

    private func reset() {
        PersistenceService.clear()
        viewModel.hasConfigured_reset()
        dismiss()
    }
}

// MARK: - Theme swatch cell

private struct ThemeSwatchCell: View {
    let style:      AppThemeStyle
    let isSelected: Bool
    let onTap:      () -> Void

    private var swatchTheme: AppTheme {
        style == .system ? .dark : AppTheme.make(for: style)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DS.Spacing.s) {
                ZStack {
                    // Background swatch
                    RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                        .fill(swatchTheme.background)
                        .frame(height: 56)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.m, style: .continuous)
                                .strokeBorder(
                                    isSelected
                                        ? swatchTheme.accentBlue
                                        : Color.white.opacity(0.08),
                                    lineWidth: isSelected ? 2 : 1
                                )
                        )

                    // Mini week-dot accent
                    HStack(spacing: 3) {
                        ForEach(0..<4, id: \.self) { i in
                            RoundedRectangle(cornerRadius: 2, style: .continuous)
                                .fill(i == 2 ? swatchTheme.weekCurrent : swatchTheme.weekPast.opacity(0.6))
                                .frame(width: 8, height: 8)
                        }
                    }

                    // System icon
                    if style == .system {
                        Image(systemName: "circle.lefthalf.filled")
                            .font(.system(size: 18))
                            .foregroundStyle(Color.white.opacity(0.6))
                    }

                    // Selected checkmark
                    if isSelected {
                        VStack {
                            HStack {
                                Spacer()
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundStyle(swatchTheme.accentBlue)
                                    .padding(5)
                            }
                            Spacer()
                        }
                    }
                }

                Text(style.rawValue)
                    .font(.lifeLabel)
                    .foregroundStyle(isSelected ? Color.textPrimary : Color.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Grid style cell

private struct GridStyleCell: View {
    let style:      GridStyle
    let isSelected: Bool
    let theme:      AppTheme
    let onTap:      () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: DS.Spacing.s) {
                // Mini grid preview (4×4)
                VStack(spacing: style.cellGap) {
                    ForEach(0..<4, id: \.self) { row in
                        HStack(spacing: style.cellGap) {
                            ForEach(0..<4, id: \.self) { col in
                                let isCurrent = row == 1 && col == 2
                                let isPast    = row * 4 + col < 6
                                RoundedRectangle(cornerRadius: style.cornerRadius * 0.6, style: .continuous)
                                    .fill(
                                        isCurrent ? theme.weekCurrent :
                                        isPast    ? theme.weekPast    :
                                                    theme.weekFuture
                                    )
                                    .frame(
                                        width:  style.cellSize * 0.9,
                                        height: style.cellSize * 0.9
                                    )
                            }
                        }
                    }
                }
                .padding(DS.Spacing.s)
                .background(
                    RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                        .fill(theme.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                                .strokeBorder(
                                    isSelected ? theme.accentBlue : theme.divider,
                                    lineWidth: isSelected ? 1.5 : 1
                                )
                        )
                )

                Text(style.rawValue)
                    .font(.lifeLabel)
                    .foregroundStyle(isSelected ? theme.textPrimary : theme.textSecondary)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Settings card modifier

private struct SettingsCard: ViewModifier {
    let theme: AppTheme
    func body(content: Content) -> some View {
        content
            .background(theme.surface)
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .strokeBorder(theme.divider, lineWidth: 1)
            )
    }
}

private extension View {
    func settingsCard(theme: AppTheme) -> some View {
        modifier(SettingsCard(theme: theme))
    }
}

// MARK: - Array safe subscript

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Notification preview sheet

private struct NotificationPreviewSheet: View {
    let tone:           NotificationTone
    let weeksLived:     Int
    let weeksRemaining: Int

    @Environment(\.dismiss) private var dismiss

    private var payloads: [NotificationPayload] {
        NotificationContentEngine.previewPayloads(
            tone:           tone,
            weeksLived:     weeksLived,
            weeksRemaining: weeksRemaining
        )
    }

    var body: some View {
        ZStack {
            Color.appBg.ignoresSafeArea()

            VStack(spacing: 0) {
                Capsule()
                    .fill(Color.appDivider)
                    .frame(width: 36, height: 4)
                    .padding(.top, DS.Spacing.m)

                VStack(alignment: .leading, spacing: DS.Spacing.s) {
                    Text("Notification Preview")
                        .font(.lifeSubhead)
                        .foregroundStyle(Color.textPrimary)
                    Text("Sample messages for \"\(tone.rawValue)\" tone")
                        .font(.lifeCaption)
                        .foregroundStyle(Color.textTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, DS.Spacing.l)
                .padding(.top, DS.Spacing.l)
                .padding(.bottom, DS.Spacing.m)

                VStack(spacing: DS.Spacing.s) {
                    ForEach(payloads.indices, id: \.self) { i in
                        MockNotificationCard(payload: payloads[i])
                    }
                }
                .padding(.horizontal, DS.Spacing.l)

                Spacer()
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }
}

private struct MockNotificationCard: View {
    let payload: NotificationPayload

    var body: some View {
        HStack(alignment: .top, spacing: DS.Spacing.m) {
            RoundedRectangle(cornerRadius: DS.Radius.s, style: .continuous)
                .fill(LinearGradient.accentDiagonal)
                .frame(width: 36, height: 36)
                .overlay(
                    Image(systemName: "square.grid.3x3.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                )

            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Life in Weeks")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Text("now")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color.textTertiary)
                }
                Text(payload.title)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.textPrimary)
                Text(payload.body)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(Color.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(DS.Spacing.m)
        .glassCard()
    }
}

// MARK: - FAQ Data

fileprivate struct FAQItem: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

fileprivate let faqItems: [FAQItem] = {
    let group1: [FAQItem] = [
        FAQItem(
            question: "What is Life in Weeks?",
            answer: "A visual reminder of your life as a grid of weeks. Each square = one week — lived weeks are filled, your current week pulses, and future weeks are faint. The goal: make time feel real so you live more intentionally."
        ),
        FAQItem(
            question: "How does the week grid work?",
            answer: "The grid spans from your birth week to the last projected week based on your life expectancy. Each row is roughly one year. Lived weeks appear solid, the current week is highlighted in blue, and future weeks are shown faintly."
        ),
        FAQItem(
            question: "How accurate is the week count?",
            answer: "Weeks are calculated from the Monday of your birth week to the Monday of the current week, matching the ISO calendar standard. The count is accurate to within one day depending on which day of the week you were born."
        ),
        FAQItem(
            question: "What do the colors mean?",
            answer: "Bright solid cells = weeks you've lived. The glowing blue cell = your current week. Faint cells = weeks remaining. Milestone weeks (every 52nd, i.e. each birthday) have a gold border."
        ),
        FAQItem(
            question: "Why do I need to enter my birthday?",
            answer: "Your birthday is the starting point for the entire grid. Without it, the app can't calculate how many weeks you've lived. Your data is private and stored only on your device — never uploaded."
        )
    ]
    let group2: [FAQItem] = [
        FAQItem(
            question: "Is my data private?",
            answer: "Yes. Your name, birthday and life expectancy are stored only on your device and are never sent to us or to anyone else. There is no account system. The app shows ads from Google AdMob, which may use your device's advertising identifier only if you allow tracking; buying Remove Ads turns ads off."
        ),
        FAQItem(
            question: "How do I change my life expectancy?",
            answer: "Go to Settings → Life Settings and drag the slider (50–120 years). This only changes the total number of weeks shown — it doesn't affect how many weeks you've already lived."
        ),
        FAQItem(
            question: "How do notifications work?",
            answer: "A weekly reminder sends a short emotionally resonant message. You choose the day, time, and tone (Gentle, Balanced, or Deep). Special messages fire on your birthday week and New Year. Messages rotate to avoid repetition."
        ),
        FAQItem(
            question: "What are milestone weeks?",
            answer: "Significant life points — each birthday, major fractions (25%, 50%, 75%), and decade markers (30, 40, 50). The app detects these and sends specially crafted messages when you reach them."
        ),
        FAQItem(
            question: "What does the widget show?",
            answer: "Your weeks lived, weeks remaining, progress percentage, and a rotating daily message. It refreshes every midnight. Add it via the iOS widget gallery — long-press your home screen, tap +, and search 'Lifeline'."
        )
    ]
    let group3: [FAQItem] = [
        FAQItem(
            question: "Why isn't the widget updating?",
            answer: "Widgets refresh at midnight each day. If you recently updated your birthday, the widget reloads immediately. If it still shows old data, remove and re-add the widget from your home screen."
        ),
        FAQItem(
            question: "Is Lifeline Weeks free?",
            answer: "Yes. Every feature — the grid, all six themes, notifications and widgets — is free. The app shows ads; a one-time Remove Ads purchase turns them off for good. If you bought the old Premium unlock, you're already ad-free."
        ),
        FAQItem(
            question: "How do I change the theme?",
            answer: "Settings → Appearance. Choose from System (follows iOS auto), Light, Dark, Midnight, Beige or AMOLED. Tap any swatch to switch with an animated transition."
        ),
        FAQItem(
            question: "What is the notification tone?",
            answer: "'Gentle' = soft and calm. 'Balanced' = thought-provoking but not heavy. 'Deep' = raw and existential for those who want a stronger dose of perspective. Preview sample messages before choosing."
        ),
        FAQItem(
            question: "How do I reset the app?",
            answer: "Settings → scroll to the bottom → tap 'Reset & start over'. This permanently clears your profile and returns you to onboarding. This action cannot be undone."
        )
    ]
    return group1 + group2 + group3
}()

// MARK: - FAQ View

struct FAQView: View {
    let theme: AppTheme
    @Environment(\.dismiss) private var dismiss
    @State private var expanded: UUID? = nil

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("FAQ")
                                .font(.lifeStat)
                                .foregroundStyle(theme.textPrimary)
                            Text("Frequently asked questions")
                                .font(.lifeCaption)
                                .foregroundStyle(theme.textTertiary)
                        }
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 24))
                                .foregroundStyle(theme.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.xl)
                    .padding(.bottom, DS.Spacing.l)

                    // FAQ Items
                    VStack(spacing: DS.Spacing.s) {
                        ForEach(faqItems) { item in
                            FAQRow(
                                item: item,
                                isExpanded: expanded == item.id,
                                theme: theme,
                                onTap: {
                                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                        expanded = expanded == item.id ? nil : item.id
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.bottom, DS.Spacing.xxl)
                }
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .presentationCornerRadius(24)
        .presentationDragIndicator(.visible)
    }
}

// MARK: - FAQ Row

private struct FAQRow: View {
    let item: FAQItem
    let isExpanded: Bool
    let theme: AppTheme
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top, spacing: DS.Spacing.m) {
                    Text(item.question)
                        .font(.lifeBody)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.textPrimary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: DS.Spacing.s)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accentBlue)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                        .padding(.top, 2)
                }
                .padding(DS.Spacing.l)

                if isExpanded {
                    Divider()
                        .background(theme.divider)
                        .padding(.horizontal, DS.Spacing.l)

                    Text(item.answer)
                        .font(.lifeBody)
                        .foregroundStyle(theme.textSecondary)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(DS.Spacing.l)
                        .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
            .background(
                RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                    .fill(theme.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous)
                            .strokeBorder(
                                isExpanded ? theme.accentBlue.opacity(0.35) : theme.divider,
                                lineWidth: isExpanded ? 1.5 : 1
                            )
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack { SettingsView() }
        .environmentObject(LifeViewModel())
        .environmentObject(ThemeManager())
}
