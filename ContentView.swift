//
//  ContentView.swift
//  Market Differentials
//
//  Created by Tamzid  Ullah on 9/7/25.
//

import SwiftUI
import StoreKit

struct ContentView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var purchaseManager: PurchaseManager
    @EnvironmentObject var dataManager: DataManager

    @State private var isBootstrapping = true
    @State private var purchaseError: String?

    var body: some View {
        Group {
            if isBootstrapping {
                SplashView()
            } else if authManager.isAuthenticated {
                MainTabView() // your existing tabs
            } else {
                LoginView()   // your existing login screen
            }
        }
        // Initial load + entitlement refresh
        .task { await bootstrap() }
        // Live transaction listener keeps premium flag current
        .task { await watchTransactions() }
        // Simple surfaced error (optional)
        .alert("Purchase Error",
               isPresented: .init(
                    get: { purchaseError != nil },
                    set: { if !$0 { purchaseError = nil } })
        ) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(purchaseError ?? "")
        }
    }

    @MainActor
    private func bootstrap() async {
        await purchaseManager.loadProducts()
        await refreshPremiumFromEntitlements()
        authManager.checkPremiumStatus() // fallback from UserDefaults if needed
        isBootstrapping = false
    }

    private func watchTransactions() async {
        for await update in Transaction.updates {
            switch update {
            case .verified(let transaction):
                await transaction.finish()
                await MainActor.run {
                    purchaseManager.purchasedProductIDs.insert(transaction.productID)
                    authManager.isPremium = true
                    UserDefaults.standard.set(true, forKey: "isPremium")
                }
            case .unverified(_, let error):
                await MainActor.run { purchaseError = error.localizedDescription }
            }
        }
    }

    @MainActor
    private func refreshPremiumFromEntitlements() async {
        var hasPremium = false
        let allIDs = PurchaseManager.ProductID.allCases.map(\.rawValue)

        // Iterate the async sequence for each product you consider "premium".
        for id in allIDs {
            // Yields VerificationResult<Transaction> values
            for await result in Transaction.currentEntitlements(for: id) {
                if case .verified(let txn) = result, txn.revocationDate == nil {
                    hasPremium = true
                    break
                }
            }
            if hasPremium { break }
        }

        authManager.isPremium = hasPremium
    }
}

private struct SplashView: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView().controlSize(.large)
            Text("Loading…").foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationManager())
            .environmentObject(PurchaseManager())
            .environmentObject(DataManager())
    }
}


#Preview {
    ContentView()
}
