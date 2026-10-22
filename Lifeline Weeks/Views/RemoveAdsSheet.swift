import SwiftUI
import StoreKit

/// The only purchase in Lifeline Weeks: a one-time "Remove Ads".
/// Every feature (all themes included) is free; this only turns ads off.
struct RemoveAdsSheet: View {
    @ObservedObject private var adFree = AdFreeStatus.shared
    @Environment(\.dismiss) private var dismiss

    @State private var isPurchasing   = false
    @State private var isRestoring    = false
    @State private var appeared       = false
    @State private var product:        Product? = nil
    @State private var purchaseError:  String?  = nil

    private struct Benefit: Identifiable {
        let id = UUID()
        let icon: String
        let title: String
        let detail: String
    }

    private let benefits: [Benefit] = [
        Benefit(icon: "eye.slash.fill", title: "No ads",
                detail: "No banner or full-screen ads, ever"),
        Benefit(icon: "infinity", title: "One-time purchase",
                detail: "No subscription. Yours forever"),
        Benefit(icon: "heart.fill", title: "Support the app",
                detail: "Helps an indie developer keep building")
    ]

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
                        benefitList
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
            Image(systemName: "nosign")
                .font(.system(size: 44, weight: .semibold))
                .foregroundStyle(Color.accentColor)
                .opacity(appeared ? 1 : 0)

            Text("Remove Ads")
                .font(.system(size: 38, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)

            Text("Every feature and every theme is free.\nRemove ads once and keep your life view calm.")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(.white.opacity(0.5))
                .multilineTextAlignment(.center)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)
        }
        .animation(.easeOut(duration: 0.55), value: appeared)
    }

    private var benefitList: some View {
        VStack(spacing: 0) {
            ForEach(Array(benefits.enumerated()), id: \.element.id) { i, benefit in
                benefitRow(benefit, delay: Double(i) * 0.08)
                if i < benefits.count - 1 {
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

    private func benefitRow(_ benefit: Benefit, delay: Double) -> some View {
        HStack(spacing: DS.Spacing.l) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: benefit.icon)
                    .font(.system(size: 16))
                    .foregroundStyle(Color.accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(benefit.title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                Text(benefit.detail)
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
            if adFree.isAdFree {
                Label("You're ad-free. Thank you!", systemImage: "checkmark.seal.fill")
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Color.white.opacity(0.08),
                                in: RoundedRectangle(cornerRadius: DS.Radius.l, style: .continuous))
            } else {
                // Primary CTA — live price from App Store Connect
                Button(action: purchase) {
                    ZStack {
                        if isPurchasing {
                            ProgressView().tint(.white)
                        } else {
                            Text(product.map { "Remove Ads — \($0.displayPrice)" } ?? "Remove Ads")
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
            }

            // Inline error (shown only when purchase/restore fails)
            if let err = purchaseError {
                Text(err)
                    .font(.system(size: 11, design: .rounded))
                    .foregroundStyle(.red.opacity(0.8))
                    .multilineTextAlignment(.center)
                    .transition(.opacity)
            }

            // Apple ID purchase description
            Text("One-time payment charged to your Apple ID at confirmation. No subscription, no recurring charges.")
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
        RemoveAdsSheet()
    }
}
