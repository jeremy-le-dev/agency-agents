import Foundation
import WidgetKit

@MainActor
final class WidgetDataManager {
    static let shared = WidgetDataManager()

    private let defaults: UserDefaults?

    private init() {
        defaults = UserDefaults(suiteName: AppGroupConstants.suiteName)
    }

    var isBalanceHidden: Bool {
        defaults?.bool(forKey: AppGroupConstants.balanceHiddenKey) ?? false
    }

    func setBalanceHidden(_ hidden: Bool) {
        defaults?.set(hidden, forKey: AppGroupConstants.balanceHiddenKey)
        if let existing = load() {
            let updated = WidgetSnapshot(
                totalBalance: existing.totalBalance,
                currencyCode: existing.currencyCode,
                lastUpdated: existing.lastUpdated,
                topAccounts: existing.topAccounts,
                isBalanceHidden: hidden
            )
            if let data = try? JSONEncoder().encode(updated) {
                defaults?.set(data, forKey: AppGroupConstants.accountsSnapshotKey)
            }
        }
        reloadWidget()
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
                },
            isBalanceHidden: isBalanceHidden
        )

        defaults.set(NSDecimalNumber(decimal: snapshot.totalBalance).doubleValue, forKey: AppGroupConstants.totalBalanceKey)
        defaults.set(snapshot.lastUpdated, forKey: AppGroupConstants.lastUpdatedKey)
        defaults.set(snapshot.currencyCode, forKey: AppGroupConstants.currencyCodeKey)

        if let data = try? JSONEncoder().encode(widgetSnapshot) {
            defaults.set(data, forKey: AppGroupConstants.accountsSnapshotKey)
        }

        reloadWidget()
    }

    func reloadWidget() {
        WidgetCenter.shared.reloadTimelines(ofKind: AppGroupConstants.widgetKind)
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
