import SwiftUI

@main
struct PatrimoineApp: App {
    @State private var aggregationService = AggregationService()
    @State private var analyticsService = AnalyticsService()
    @State private var biometricLock = BiometricLockManager()

    var body: some Scene {
        WindowGroup {
            ZStack {
                AppColors.background.ignoresSafeArea()
                MainTabView()
            }
            .environment(aggregationService)
            .environment(analyticsService)
            .environment(biometricLock)
            .biometricLock()
                .sheet(isPresented: powensSheetBinding) {
                    if let url = aggregationService.powensConnectURL {
                        PowensConnectSheet(connectURL: url) { result in
                            handlePowensResult(result)
                        }
                    }
                }
                .onOpenURL { url in
                    guard url.scheme == "patrimoine" else { return }
                    let isPowensCallback = url.host == "powens" || url.path.contains("powens")
                    if isPowensCallback {
                        Task { await aggregationService.completePowensConnection() }
                    }
                }
        }
    }

    private var powensSheetBinding: Binding<Bool> {
        Binding(
            get: { aggregationService.showPowensConnect && aggregationService.powensConnectURL != nil },
            set: { isPresented in
                if !isPresented { aggregationService.cancelPowensConnection() }
            }
        )
    }

    private func handlePowensResult(_ result: Result<Int?, Error>) {
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
