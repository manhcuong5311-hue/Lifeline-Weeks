import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel    = LifeViewModel()
    @StateObject private var themeManager = ThemeManager()

    @Environment(\.colorScheme) private var systemColorScheme

    @State private var scrollTrigger       = false
    @State private var celebrationBanner:  String?

    private var theme: AppTheme { themeManager.current }

    var body: some View {
        ZStack {
            // ── Layer 1: base gradient from current theme ─────────────────
            theme.backgroundGradient
                .ignoresSafeArea()

            // ── Layer 2: subtle radial accent at top ─────────────────────
            RadialGradient(
                colors: [theme.accentPurple.opacity(0.10), .clear],
                center: .top,
                startRadius: 0,
                endRadius: 380
            )
            .ignoresSafeArea()

            // ── Layer 3: app content ──────────────────────────────────────
            NavigationStack {
                Group {
                    if viewModel.hasConfigured {
                        mainContent
                            .adBannerInset()
                    } else {
                        OnboardingView()
                    }
                }
                .navigationTitle("Life in Weeks")
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(theme.background.opacity(0.95), for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(theme.colorScheme == .light ? .light : .dark, for: .navigationBar)
            }
        }
        .preferredColorScheme(theme.colorScheme)
        .environmentObject(viewModel)
        .environmentObject(themeManager)
        .overlay(alignment: .top) { milestoneOverlay }
        .onChange(of: viewModel.weeksLived) { old, new in
            guard old > 0 else { return }
            checkMilestone(from: old, to: new)
        }
        .onChange(of: systemColorScheme) { _, scheme in
            themeManager.updateSystemScheme(scheme)
        }
        // Consent / ATT / ads start only once the life grid is on screen —
        // never during onboarding.
        .onAppear {
            if viewModel.hasConfigured { AdsManager.shared.activate() }
        }
        .onChange(of: viewModel.hasConfigured) { _, configured in
            if configured { AdsManager.shared.activate() }
        }
    }

    // MARK: - Main content

    private var mainContent: some View {
        ScrollViewReader { proxy in
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        LifeGridView(
                            weeks:            viewModel.weeks,
                            milestoneIndices: viewModel.milestoneIndices,
                            birthDate:        viewModel.birthDate
                        )
                    } header: {
                        HeaderView(
                            progress:       viewModel.progress,
                            weeksLived:     viewModel.weeksLived,
                            weeksRemaining: viewModel.weeksRemaining,
                            userName:       viewModel.userName,
                            insight:        viewModel.currentInsight
                        )
                        .background(theme.background.opacity(0.92))
                        .overlay(alignment: .bottom) {
                            Divider().background(theme.divider)
                        }
                    }
                }
            }
            .onChange(of: viewModel.weeks.isEmpty) { _, isEmpty in
                if !isEmpty { scrollToCurrent(proxy: proxy) }
            }
            .onChange(of: scrollTrigger) { _, _ in scrollToCurrent(proxy: proxy) }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    HapticFeedback.light()
                    scrollTrigger.toggle()
                } label: {
                    Image(systemName: "scope")
                        .foregroundStyle(theme.textSecondary)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: DS.Spacing.l) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundStyle(theme.textSecondary)
                    }
                    ShareButton(viewModel: viewModel)
                }
            }
        }
    }

    // MARK: - Scroll helper

    private func scrollToCurrent(proxy: ScrollViewProxy) {
        guard let current = viewModel.weeks.first(where: { $0.state == .current }) else { return }
        withAnimation(.easeInOut(duration: 0.65)) {
            proxy.scrollTo(current.id, anchor: .center)
        }
    }

    // MARK: - Milestone banner

    @ViewBuilder
    private var milestoneOverlay: some View {
        if let banner = celebrationBanner {
            Text(banner)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundStyle(theme.textPrimary)
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.s + 2)
                .background(
                    Capsule()
                        .fill(theme.backgroundElevated)
                        .overlay(Capsule().strokeBorder(theme.accentBlue.opacity(0.4), lineWidth: 1))
                )
                .padding(.top, DS.Spacing.xl)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private func checkMilestone(from oldWeeks: Int, to newWeeks: Int) {
        let total = LifeCalculator.totalWeeks(lifeExpectancyYears: viewModel.lifeExpectancy)
        guard let crossed = MilestoneEngine.newlyCrossed(from: oldWeeks, to: newWeeks,
                                                          totalWeeks: total) else { return }
        HapticFeedback.success()
        withAnimation(.spring(response: 0.45, dampingFraction: 0.7)) {
            celebrationBanner = "✦ \(crossed.title)"
        }
        Task {
            try? await Task.sleep(for: .seconds(3))
            withAnimation { celebrationBanner = nil }
        }
    }
}

#Preview { HomeView() }
