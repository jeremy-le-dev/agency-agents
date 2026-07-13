import Foundation

@MainActor
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    func save(snapshot: PortfolioSnapshot) {
        guard let defaults else { return }

        let widgetSnapshot = WidgetSnapshot(
            totalBalance: NSDecimalNumber(decimal: snapshot.totalBalance).doubleValue,
            currencyCode: snapshot.currencyCode,
            lastUpdated: snapshot.lastUpdated,
            topAccounts: snapshot.accounts
                .sorted { $0.balance > $1.balance }
                .prefix(3)
                .map {
                    WidgetAccountSummary(
                        id: $0.id,
                        name: $0.name,
                        institution: $0.institution.rawValue,
                        balance: NSDecimalNumber(decimal: $0.balance).doubleValue,
                        colorHex: $0.institution.brandColorHex
                    )
                }
        )

        defaults.set(NSDecimalNumber(decimal: snapshot.totalBalance).doubleValue, forKey: AppGroupConstants.totalBalanceKey)
        defaults.set(snapshot.lastUpdated, forKey: AppGroupConstants.lastUpdatedKey)
        defaults.set(snapshot.currencyCode, forKey: AppGroupConstants.currencyCodeKey)

        if let data = try? JSONEncoder().encode(widgetSnapshot) {
            defaults.set(data, forKey: AppGroupConstants.accountsSnapshotKey)
        }
    }

    func load() -> WidgetSnapshot? {
        guard let defaults,
              let data = defaults.data(forKey: AppGroupConstants.accountsSnapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }
}
