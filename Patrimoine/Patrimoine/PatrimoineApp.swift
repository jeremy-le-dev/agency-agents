import SwiftUI

@main
struct PatrimoineApp: App {
    @State private var aggregationService = AggregationService()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environment(aggregationService)
        }
    }
}
