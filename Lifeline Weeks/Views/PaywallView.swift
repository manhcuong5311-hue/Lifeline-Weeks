import SwiftUI
import StoreKit

struct PaywallView: View {
    @EnvironmentObject private var viewModel: LifeViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing   = false
    @State private var isRestoring    = false
    @State private var appeared       = false
    @State private var product:        Product? = nil
    @State private var purchaseError:  String?  = nil

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color(white: 0.06), Color(white: 0.02)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                dismissHandle

                ScrollView(showsIndicators: false) {
                    VStack(spacing: DS.Spacing.xxl) {
                        heroSection
                        featureList
                        Spacer(minLength: DS.Spacing.xl)
                    }
                    .padding(.horizontal, DS.Spacing.l)
                    .padding(.top, DS.Spacing.xl)
                }

                ctaSection
            }
        }
        .task {
            withAnimation(.easeOut(duration: 0.5).delay(0.1)) { appeared = true }
            product = await PremiumService.fetchProduct()
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(28)
    }

    // MARK: - Sections

    private var dismissHandle: some View {
        Capsule()
            .fill(Color.white.opacity(0.2))
            .frame(width: 36, height: 4)
            .padding(.top, 12)
    }

    private var heroSection: some View {
        VStack(spacing: DS.Spacing.m) {
            Text("See your life\nclearly.")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Text("Unlock the full experience.\nEvery week, every milestone, every moment.")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
        }
        .animation(.easeOut(duration: 0.55), value: appeared)
    }

    private var featureList: some View {
        VStack(spacing: 0) {
            ForEach(Array(PremiumFeature.allCases.enumerated()), id: \.element) { i, feature in
                featureRow(feature, delay: Double(i) * 0.08)
                if feature != PremiumFeature.allCases.last {
                    Divider()
                        .background(Color.white.opacity(0.08))
                        .padding(.leading, 56)
                }
            }
        }
        .background(Color.white.opacity(0.05),
                    in: RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: DS.Radius.xl, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
        )
    }

    private func featureRow(_ feature: PremiumFeature, delay: Double) -> some View {
        HStack(spacing: DS.Spacing.l) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: feature.systemImage)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(feature.rawValue)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(feature.description)
                    .font(.system(size: 13, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
            }

            Spacer()

            Image(systemName: "checkmark")
                .font(.caption.weight(.bold))
                .foregroundStyle(Color.accentColor)
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.vertical, DS.Spacing.m)
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 10)
        .animation(.easeOut(duration: 0.45).delay(0.3 + delay), value: appeared)
    }

    private var ctaSection: some View {
        VStack(spacing: DS.Spacing.m) {
            // Live price from App Store Connect (falls back to em-dash while loading)
            Group {
                if let p = product {
                    Text("\(p.displayPrice)  ·  One-time purchase, forever")
                } else {
                    Text("—  ·  One-time purchase, forever")
                }
            }
            .font(.system(size: 13, design: .rounded))
            .foregroundStyle(.white.opacity(0.4))

            // Primary CTA
            Button(action: purchase) {
                ZStack {
                    if isPurchasing {
                        ProgressView().tint(.white)
                    } else {
                        Text("Unlock Full Life View")
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 17)
                .background(product == nil ? Color.accentColor.opacity(0.5) : Color.accentColor)
                .foregroundStyle(.white)
                .clipShape(RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            }
            .disabled(isPurchasing || isRestoring || product == nil)

            // Inline error (shown only when purchase/restore fails)
            if let err = purchaseError {
                Text(err)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            // Apple ID purchase description
            Text("Payment will be charged to your Apple ID at confirmation. This is a one-time purchase — no subscription, no recurring charges, no expiry. Yours forever.")
                .font(.system(size: 11, design: .rounded))
                .foregroundStyle(.white.opacity(0.3))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            // Links row: Privacy Policy · EULA
            HStack(spacing: DS.Spacing.m) {
                Link("Privacy Policy", destination: URL(string: "https://manhcuong5311-hue.github.io/Lifeline-Weeks/")!)
                Text("·").foregroundStyle(.white.opacity(0.2))
                Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
            }
            .font(.system(size: 11, design: .rounded))
            .foregroundStyle(.white.opacity(0.35))

            // Restore
            Button(action: restore) {
                Text(isRestoring ? "Restoring…" : "Restore Purchases")
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(.white.opacity(0.45))
                    .underline()
            }
            .disabled(isPurchasing || isRestoring)
        }
        .padding(.horizontal, DS.Spacing.l)
        .padding(.top, DS.Spacing.m)
        .padding(.bottom, 40)
        .background(Color.appBgElevated)
    }

    // MARK: - Actions

    private func purchase() {
        isPurchasing    = true
        purchaseError   = nil
        HapticFeedback.light()
        Task { @MainActor in
            do {
                let ok = try await PremiumService.purchase()
                isPurchasing = false
                if ok {
                    HapticFeedback.success()
                    viewModel.isPremium = true
                    dismiss()
                }
            } catch StoreError.purchasePending {
                isPurchasing  = false
                purchaseError = "Purchase is pending. You'll be notified when it's approved."
            } catch StoreError.productNotFound {
                isPurchasing  = false
                purchaseError = "Could not reach the App Store. Check your connection and try again."
            } catch {
                isPurchasing  = false
                purchaseError = error.localizedDescription
            }
        }
    }

    private func restore() {
        isRestoring   = true
        purchaseError = nil
        Task { @MainActor in
            let ok = await PremiumService.restorePurchases()
            isRestoring = false
            if ok {
                HapticFeedback.success()
                viewModel.isPremium = true
                dismiss()
            } else {
                purchaseError = "No previous purchase found on this Apple ID."
            }
        }
    }
}

// MARK: - Preview

#Preview {
    Color.clear.sheet(isPresented: .constant(true)) {
        PaywallView().environmentObject(LifeViewModel())
    }
}
