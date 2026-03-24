import SwiftUI
import StoreKit

// MARK: - Model

private struct GuideStep: Identifiable {
    let id:          Int
    let symbol:      String
    let symbolColor: Color
    let title:       String
    let body:        String
    let tip:         String?
}

private let steps: [GuideStep] = [
    GuideStep(
        id: 0,
        symbol:      "hand.tap.fill",
        symbolColor: Color(red: 0.47, green: 0.65, blue: 1.00),
        title:       "Go to your Home Screen",
        body:        "Press and hold any empty area on your Home Screen until the icons begin to jiggle.",
        tip:         "Tip: Make sure you're pressing on a blank space, not on an app icon."
    ),
    GuideStep(
        id: 1,
        symbol:      "plus.circle.fill",
        symbolColor: Color(red: 0.35, green: 0.82, blue: 0.55),
        title:       "Tap the + button",
        body:        "A '+' button appears in the top-left corner of your screen. Tap it to open the widget gallery.",
        tip:         nil
    ),
    GuideStep(
        id: 2,
        symbol:      "magnifyingglass",
        symbolColor: Color(red: 1.00, green: 0.75, blue: 0.35),
        title:       "Search for Life in Weeks",
        body:        "Type \"Life in Weeks\" in the search bar at the top of the gallery and tap the app.",
        tip:         "Tip: You can also scroll down to find it in your installed apps list."
    ),
    GuideStep(
        id: 3,
        symbol:      "rectangle.3.group.fill",
        symbolColor: Color(red: 0.72, green: 0.52, blue: 1.00),
        title:       "Choose a size",
        body:        "Swipe left or right to pick Small or Medium. Both show your life progress and a daily message.",
        tip:         "Tip: Medium shows more detail — weeks lived, weeks remaining, and a motivational quote."
    ),
    GuideStep(
        id: 4,
        symbol:      "checkmark.circle.fill",
        symbolColor: Color(red: 0.47, green: 0.65, blue: 1.00),
        title:       "Tap \"Add Widget\"",
        body:        "Tap the blue 'Add Widget' button to place it on your Home Screen, then tap 'Done' to save.",
        tip:         nil
    ),
]

// MARK: - Main view

struct WidgetGuideView: View {

    @Environment(\.dismiss)        private var dismiss
    @Environment(\.requestReview)  private var requestReview

    @State private var currentStep  = 0
    @State private var direction    = 1   // +1 forward, -1 backward
    @State private var showComplete = false
    @State private var symbolScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(white: 0.07), Color(white: 0.03)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Drag handle ─────────────────────────────────────
                Capsule()
                    .fill(Color.white.opacity(0.18))
                    .frame(width: 36, height: 4)
                    .padding(.top, 14)

                if showComplete {
                    completionView
                        .transition(.asymmetric(
                            insertion:  .move(edge: .trailing).combined(with: .opacity),
                            removal:    .move(edge: .leading).combined(with: .opacity)
                        ))
                } else {
                    stepContent
                        .transition(.asymmetric(
                            insertion:  .move(edge: direction > 0 ? .trailing : .leading)
                                            .combined(with: .opacity),
                            removal:    .move(edge: direction > 0 ? .leading : .trailing)
                                            .combined(with: .opacity)
                        ))
                }
            }
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    // MARK: - Step content

    private var stepContent: some View {
        let step = steps[currentStep]
        return VStack(spacing: 0) {
            Spacer()

            // ── Step indicator ───────────────────────────────────────
            stepIndicator

            Spacer(minLength: 32)

            // ── Symbol card ──────────────────────────────────────────
            ZStack {
                Circle()
                    .fill(step.symbolColor.opacity(0.12))
                    .frame(width: 120, height: 120)
                Circle()
                    .strokeBorder(step.symbolColor.opacity(0.2), lineWidth: 1)
                    .frame(width: 120, height: 120)
                Image(systemName: step.symbol)
                    .font(.system(size: 48, weight: .semibold))
                    .foregroundStyle(step.symbolColor)
                    .scaleEffect(symbolScale)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)) {
                    symbolScale = 1.08
                }
            }

            Spacer(minLength: 28)

            // ── Step number ──────────────────────────────────────────
            Text("STEP \(currentStep + 1) OF \(steps.count)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(.white.opacity(0.35))
                .tracking(1.5)

            Spacer(minLength: 12)

            // ── Title ────────────────────────────────────────────────
            Text(step.title)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer(minLength: 14)

            // ── Body ─────────────────────────────────────────────────
            Text(step.body)
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.65))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            // ── Tip ──────────────────────────────────────────────────
            if let tip = step.tip {
                Spacer(minLength: 16)
                HStack(spacing: 8) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(red: 1.00, green: 0.80, blue: 0.30))
                    Text(tip)
                        .font(.system(size: 12, design: .rounded))
                        .foregroundStyle(.white.opacity(0.45))
                        .multilineTextAlignment(.leading)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.05))
                )
                .padding(.horizontal, 24)
            }

            Spacer()

            // ── Navigation buttons ───────────────────────────────────
            navButtons
        }
        .id(currentStep)   // force redraw on step change for transition
    }

    // MARK: - Step indicator

    private var stepIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<steps.count, id: \.self) { i in
                Capsule()
                    .fill(i == currentStep
                          ? Color(red: 0.47, green: 0.65, blue: 1.00)
                          : Color.white.opacity(0.18))
                    .frame(width: i == currentStep ? 22 : 8, height: 8)
                    .animation(.spring(response: 0.35, dampingFraction: 0.7), value: currentStep)
            }
        }
    }

    // MARK: - Navigation

    private var navButtons: some View {
        VStack(spacing: 12) {
            // Primary action
            Button(action: advance) {
                Text(currentStep < steps.count - 1 ? "Next" : "I've added the widget!")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.47, green: 0.65, blue: 1.00),
                                     Color(red: 0.55, green: 0.45, blue: 1.00)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)

            // Back / skip
            HStack {
                if currentStep > 0 {
                    Button("Back") {
                        direction = -1
                        withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                            currentStep -= 1
                            symbolScale  = 1.0
                        }
                    }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.4))
                }

                Spacer()

                Button("Skip guide") { dismiss() }
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.3))
            }
            .padding(.horizontal, 28)
        }
        .padding(.bottom, 44)
    }

    private func advance() {
        HapticFeedback.light()
        if currentStep < steps.count - 1 {
            direction = 1
            withAnimation(.spring(response: 0.38, dampingFraction: 0.82)) {
                currentStep += 1
                symbolScale  = 1.0
            }
        } else {
            // Guide finished → show completion
            withAnimation(.spring(response: 0.42, dampingFraction: 0.80)) {
                showComplete = true
            }
            // Trigger App Store review after a short delay
            Task {
                try? await Task.sleep(for: .seconds(0.8))
                requestReview()
            }
        }
    }

    // MARK: - Completion screen

    private var completionView: some View {
        VStack(spacing: 0) {
            Spacer()

            // Celebration icon
            ZStack {
                Circle()
                    .fill(Color(red: 0.35, green: 0.82, blue: 0.55).opacity(0.12))
                    .frame(width: 130, height: 130)
                Text("🎉")
                    .font(.system(size: 56))
            }

            Spacer(minLength: 28)

            Text("Widget added!")
                .font(.system(size: 30, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Spacer(minLength: 14)

            Text("Your life grid is now on your Home Screen.\nYou'll see a new week every day — a quiet reminder to make it count.")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.6))
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .padding(.horizontal, 32)

            Spacer(minLength: 32)

            // Rating card
            VStack(spacing: 12) {
                HStack(spacing: 6) {
                    ForEach(0..<5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                            .foregroundStyle(Color(red: 1.00, green: 0.80, blue: 0.30))
                    }
                }
                Text("If Life in Weeks is helping you\nlive more intentionally, a review\nmeans the world ✨")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)

                // Direct App Store review link as fallback
                Link(destination: AppConfig.reviewURL) {
                    Text("Write a Review →")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color(red: 0.47, green: 0.65, blue: 1.00))
                }
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)

            Spacer()

            // Done button
            Button {
                HapticFeedback.success()
                dismiss()
            } label: {
                Text("Done")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(
                        LinearGradient(
                            colors: [Color(red: 0.47, green: 0.65, blue: 1.00),
                                     Color(red: 0.55, green: 0.45, blue: 1.00)],
                            startPoint: .leading, endPoint: .trailing
                        )
                    )
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 44)
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        WidgetGuideView()
    }
}
