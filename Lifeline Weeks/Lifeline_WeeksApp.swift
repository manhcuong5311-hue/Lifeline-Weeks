//
//  Lifeline_WeeksApp.swift
//  Lifeline Weeks
//
//  Created by Sam Manh Cuong on 24/3/26.
//

import SwiftUI

@main
struct Lifeline_WeeksApp: App {

    // Kept alive for the entire app session — handles renewals, refunds,
    // family-sharing grants, and deferred purchases automatically.
    private let transactionListener = PremiumService.listenForTransactions()

    init() {
        // Reschedule notifications with latest profile data
        NotificationService.rescheduleIfNeeded()

        // Re-verify the Remove Ads entitlement against the App Store on every cold launch
        Task { await PremiumService.verifyEntitlement() }

        // Ads run only while "Remove Ads" is not owned
        AdsManager.shared.bind(isAdFree: AdFreeStatus.shared.$isAdFree)
    }

    var body: some Scene {
        WindowGroup {
            HomeView()
        }
    }
}
