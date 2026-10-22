import Foundation
import StoreKit

import Combine

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Product ID
// ─────────────────────────────────────────────────────────────────────────────
// Since 1.2 every feature is free and the app shows AdMob ads. The former
// lifetime "Premium" unlock is reused as the one-time "Remove Ads" purchase,
// so everyone who bought it before is ad-free automatically.
//     Type: Non-Consumable · Product ID: com.samcorp.lifeweeks.lifetime
// ─────────────────────────────────────────────────────────────────────────────

enum ProductID {
    static let lifetime = "com.samcorp.lifeweeks.lifetime"   // "Remove Ads" in App Store Connect
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - Store errors
// ─────────────────────────────────────────────────────────────────────────────

enum StoreError: LocalizedError {
    case productNotFound
    case failedVerification
    case purchasePending
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .productNotFound:    return "Product not found. Check App Store Connect."
        case .failedVerification: return "Transaction verification failed."
        case .purchasePending:    return "Purchase is pending approval."
        case .unknown(let e):     return e.localizedDescription
        }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - AdFreeStatus  (observable mirror for SwiftUI + AdsManager)
// ─────────────────────────────────────────────────────────────────────────────

@MainActor
final class AdFreeStatus: ObservableObject {
    static let shared = AdFreeStatus()
    @Published private(set) var isAdFree = PremiumService.isAdFree

    fileprivate func refresh() {
        if isAdFree != PremiumService.isAdFree { isAdFree = PremiumService.isAdFree }
    }
}

// ─────────────────────────────────────────────────────────────────────────────
// MARK: - PremiumService  (full StoreKit 2)
// ─────────────────────────────────────────────────────────────────────────────

struct PremiumService {

    // MARK: - Persisted entitlement (fast read)

    /// Key kept from the Premium era so former buyers stay ad-free.
    private static let premiumKey = "life.isPremium"

    /// True once "Remove Ads" (the former lifetime unlock) is owned.
    static var isAdFree: Bool {
        get { UserDefaults.standard.bool(forKey: premiumKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: premiumKey)
            Task { @MainActor in AdFreeStatus.shared.refresh() }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Fetch product
    // ─────────────────────────────────────────────────────────────────────────

    /// Returns the App Store product. Cache the result in the caller.
    static func fetchProduct() async -> Product? {
        do {
            let products = try await Product.products(for: [ProductID.lifetime])
            return products.first
        } catch {
            print("[PremiumService] fetchProduct: \(error)")
            return nil
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Purchase  (StoreKit 2)
    // ─────────────────────────────────────────────────────────────────────────

    /// Full async purchase. Throws `StoreError` on failure.
    @MainActor
    static func purchase() async throws -> Bool {
        guard let product = await fetchProduct() else {
            throw StoreError.productNotFound
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            isAdFree = true
            await transaction.finish()
            return true

        case .userCancelled:
            return false

        case .pending:
            throw StoreError.purchasePending

        @unknown default:
            return false
        }
    }

    /// Completion-handler bridge.
    static func purchase(completion: @escaping @MainActor (Bool) -> Void) {
        Task { @MainActor in
            do {
                let ok = try await purchase()
                completion(ok)
            } catch StoreError.purchasePending {
                completion(false)           // show "pending" UI if needed
            } catch {
                print("[PremiumService] purchase: \(error.localizedDescription)")
                completion(false)
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Restore  (StoreKit 2)
    // ─────────────────────────────────────────────────────────────────────────

    /// Calls `AppStore.sync()` then re-checks live entitlements.
    @MainActor
    static func restorePurchases() async -> Bool {
        do {
            try await AppStore.sync()
        } catch {
            print("[PremiumService] AppStore.sync: \(error)")
        }
        return await verifyEntitlement()
    }

    /// Completion-handler bridge.
    static func restorePurchases(completion: @escaping @MainActor (Bool) -> Void) {
        Task { @MainActor in
            let ok = await restorePurchases()
            completion(ok)
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Entitlement verification  (call on every launch)
    // ─────────────────────────────────────────────────────────────────────────

    /// Walks `Transaction.currentEntitlements`. Updates `isAdFree` as a side
    /// effect. Returns `true` when an unrevoked lifetime entitlement is found.
    ///
    /// For a non-consumable one-time purchase we only set isAdFree = false
    /// when the transaction has been explicitly REVOKED (refunded by Apple).
    /// We never revoke just because nothing is found — the user may be offline.
    @discardableResult
    @MainActor
    static func verifyEntitlement() async -> Bool {
        var foundRevoked = false

        for await result in Transaction.currentEntitlements {
            guard case .verified(let tx) = result,
                  tx.productID == ProductID.lifetime else { continue }

            if tx.revocationDate != nil {
                // Apple issued a refund — revoke access
                foundRevoked = true
            } else {
                isAdFree = true
                return true
            }
        }

        // Only revoke if we positively found a revoked transaction.
        // If entitlements are empty (offline / first launch), keep stored value.
        if foundRevoked {
            isAdFree = false
        }
        return false
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Transaction listener  (must live for the app's lifetime)
    // ─────────────────────────────────────────────────────────────────────────

    /// Call once from `Lifeline_WeeksApp.init()` and keep the task alive.
    /// Handles: new purchases, renewals, refunds, and family-sharing grants.
    @discardableResult
    static func listenForTransactions() -> Task<Void, Error> {
        Task.detached(priority: .background) {
            for await result in Transaction.updates {
                do {
                    let tx = try await checkVerified(result)
                    if await tx.productID == ProductID.lifetime {
                        // Non-consumable: grant on purchase, revoke only on refund
                        let revoked = tx.revocationDate != nil
                        await MainActor.run { isAdFree = !revoked }
                    }
                    await tx.finish()
                } catch {
                    print("[PremiumService] transaction update error: \(error)")
                }
            }
        }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // MARK: - Private helpers
    // ─────────────────────────────────────────────────────────────────────────

    private static func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:         throw StoreError.failedVerification
        case .verified(let val):  return val
        }
    }
}
