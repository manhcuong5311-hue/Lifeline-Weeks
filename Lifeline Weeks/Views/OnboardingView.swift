import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject private var viewModel:    LifeViewModel
    @EnvironmentObject private var themeManager: ThemeManager

    @State private var name:          String = ""
    @State private var birthDate:     Date = {
        Calendar.current.date(byAdding: .year, value: -30, to: Date()) ?? Date()
    }()
    @State private var lifeExpectancy = 90
    @State private var showExpectancy = false
    @State private var appeared       = false
    @State private var dateChanged    = false

    // CTA is active when user has entered a name and changed the date
    private var canConfirm: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty && dateChanged }

    private var theme: AppTheme { themeManager.current }

    private static let earliest: Date = {
        Calendar.current.date(from: DateComponents(year: 1900, month: 1, day: 1))!
    }()

    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            heroSection
            Spacer()
            inputCard
            Spacer()
            ctaButton
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.55).delay(0.1)) { appeared = true }
        }
    }

    // MARK: - Hero

    private var heroSection: some View {
        VStack(spacing: 8) {
            Text("Your life,")
                .font(.system(size: 46, weight: .bold, design: .rounded))
                .foregroundStyle(theme.textPrimary)

            Text("in weeks.")
                .font(.system(size: 46, weight: .light, design: .rounded))
                .foregroundStyle(theme.accentGradient)

            Text("One square. One week. One life.")
                .font(.lifeCaption)
                .foregroundStyle(theme.textTertiary)
                .padding(.top, 6)
        }
        .multilineTextAlignment(.center)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
        .animation(.easeOut(duration: 0.55), value: appeared)
    }

    // MARK: - Input card

    private var inputCard: some View {
        VStack(spacing: 0) {

            // ── Name row ─────────────────────────────────────────────────
            HStack {
                Text("Your name")
                    .font(.lifeBody)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                TextField("Enter your name", text: $name)
                    .font(.lifeBody)
                    .foregroundStyle(theme.textPrimary)
                    .multilineTextAlignment(.trailing)
                    .submitLabel(.done)
                    .tint(theme.accentBlue)
                    .frame(maxWidth: 180)
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.vertical, DS.Spacing.m)

            Divider()
                .background(theme.divider)
                .padding(.leading, DS.Spacing.l)

            // ── Birthday row ─────────────────────────────────────────────
            HStack {
                Text("Birthday")
                    .font(.lifeBody)
                    .foregroundStyle(theme.textPrimary)
                Spacer()
                DatePicker(
                    "",
                    selection: $birthDate,
                    in: Self.earliest...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .colorScheme(theme.colorScheme == .light ? .light : .dark)
                .onChange(of: birthDate) { _, _ in dateChanged = true }
            }
            .padding(.horizontal, DS.Spacing.l)
            .padding(.vertical, DS.Spacing.m)

            Divider()
                .background(theme.divider)
                .padding(.leading, DS.Spacing.l)

            // ── Life expectancy collapsible ───────────────────────────────
            Button {
                withAnimation(.easeInOut(duration: 0.22)) { showExpectancy.toggle() }
            } label: {
                HStack {
                    Text("Life expectancy")
                        .font(.lifeBody)
                        .foregroundStyle(theme.textPrimary)
                    Spacer()
                    Text("\(lifeExpectancy) yrs")
                        .font(.lifeBody)
                        .fontWeight(.medium)
                        .foregroundStyle(theme.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(theme.textTertiary)
                        .rotationEffect(.degrees(showExpectancy ? 90 : 0))
                }
                .padding(.horizontal, DS.Spacing.l)
                .padding(.vertical, DS.Spacing.m)
            }

            if showExpectancy {
                Divider()
                    .background(theme.divider)
                    .padding(.leading, DS.Spacing.l)
                Slider(value: expectancyBinding, in: 50...120, step: 1)
                    .tint(theme.accentBlue)
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.vertical, DS.Spacing.s)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(theme.surface)
        .clipShape(RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .strokeBorder(theme.divider, lineWidth: 1)
        )
        .padding(.horizontal, DS.Spacing.l)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 24)
        .animation(.easeOut(duration: 0.5).delay(0.1), value: appeared)
    }

    // MARK: - CTA

    private var ctaButton: some View {
        VStack(spacing: DS.Spacing.m) {
            Button(action: confirm) {
                Text("See my life")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        theme.accentDiagonal
                            .opacity(canConfirm ? 1 : 0.35)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            }
            .disabled(!canConfirm)
            .animation(.easeInOut(duration: 0.25), value: canConfirm)

            if !canConfirm {
                Text(
                    name.trimmingCharacters(in: .whitespaces).isEmpty
                        ? "Enter your name to begin"
                        : "Set your birthday above to begin"
                )
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(theme.textTertiary)
                .transition(.opacity)
                .animation(.easeInOut, value: name.isEmpty)
            }

            // ── Privacy note ──────────────────────────────────────────────
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .font(.system(size: 10))
                Text("Your data is stored on this device only. We never collect or share it.")
                    .font(.system(size: 11, design: .rounded))
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(theme.textTertiary)
            .padding(.top, DS.Spacing.xs)
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.bottom, 40)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 12)
        .animation(.easeOut(duration: 0.5).delay(0.2), value: appeared)
    }

    // MARK: - Helpers

    private var expectancyBinding: Binding<Double> {
        Binding(get: { Double(lifeExpectancy) },
                set: { lifeExpectancy = Int($0.rounded()) })
    }

    private func confirm() {
        HapticFeedback.medium()
        viewModel.userName       = name.trimmingCharacters(in: .whitespaces)
        viewModel.birthDate      = birthDate
        viewModel.lifeExpectancy = lifeExpectancy
        viewModel.saveData()
        viewModel.regenerateWeeks()
    }
}

#Preview {
    ZStack {
        LinearGradient.appBackground.ignoresSafeArea()
        OnboardingView()
            .environmentObject(LifeViewModel())
            .environmentObject(ThemeManager())
    }
    .preferredColorScheme(.light)
}
