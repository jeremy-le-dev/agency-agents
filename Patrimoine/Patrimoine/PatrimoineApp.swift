import SwiftUI

@main
struct PatrimoineApp: App {
    @State private var aggregationService = AggregationService()
    @State private var analyticsService = AnalyticsService()
    @State private var biometricLock = BiometricLockManager()

    init() {
        if UserDefaults.standard.object(forKey: "patrimoine.biometric.enabled") == nil {
            UserDefaults.standard.set(true, forKey: "patrimoine.biometric.enabled")
        }
    }

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(aggregationService)
                .environment(analyticsService)
                .environment(biometricLock)
                .biometricLock()
                .sheet(isPresented: Binding(
                    get: { aggregationService.showPowensConnect },
                    set: { if !$0 { aggregationService.cancelPowensConnection() } }
                )) {
                    if let url = aggregationService.powensConnectURL {
                        PowensConnectSheet(connectURL: url) { result in
                            switch result {
                            case .success:
                                Task { await aggregationService.completePowensConnection() }
                            case .failure(let error):
                                if let powensError = error as? PowensError, case .userCancelled = powensError {
                                    aggregationService.cancelPowensConnection()
                                } else {
                                    aggregationService.reportError(error.localizedDescription)
                                    aggregationService.cancelPowensConnection()
                                }
                            }
                        }
                    }
                }
                .onOpenURL { url in
                    guard url.scheme == "patrimoine" else { return }
                    Task { await aggregationService.completePowensConnection() }
                }
        }
    }
}
