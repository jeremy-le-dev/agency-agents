import SwiftUI

@main
struct PatrimoineApp: App {
    @State private var aggregationService = AggregationService()
    @State private var analyticsService = AnalyticsService()
    @State private var biometricLock = BiometricLockManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(aggregationService)
                .environment(analyticsService)
                .environment(biometricLock)
                .preferredColorScheme(.light)
                .biometricLock()
                .sheet(item: powensURLBinding) { item in
                    PowensConnectSheet(connectURL: item.url) { result in
                        handlePowensResult(result)
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

    private var powensURLBinding: Binding<PowensSheetItem?> {
        Binding(
            get: {
                guard aggregationService.showPowensConnect,
                      let url = aggregationService.powensConnectURL else { return nil }
                return PowensSheetItem(url: url)
            },
            set: { _ in
                aggregationService.cancelPowensConnection()
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

private struct RootView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()
            MainTabView()
        }
    }
}

private struct PowensSheetItem: Identifiable {
    let url: URL
    var id: String { url.absoluteString }
}
