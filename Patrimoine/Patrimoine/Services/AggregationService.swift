import Foundation
import Observation

@MainActor
@Observable
final class AggregationService {
    private(set) var snapshot: PortfolioSnapshot = .empty
    private(set) var isSyncing = false
    private(set) var lastError: String?

    private let storageKey = "patrimoine.accounts"
    private var connectors: [InstitutionType: InstitutionConnector] = [:]

    init() {
        for institution in InstitutionType.allCases {
            connectors[institution] = MockInstitutionConnector(institution: institution)
        }
        loadFromDisk()
        WidgetDataManager.shared.save(snapshot: snapshot)
    }

    var connectedInstitutions: Set<InstitutionType> {
        Set(snapshot.accounts.map(\.institution))
    }

    var availableInstitutions: [InstitutionType] {
        InstitutionType.allCases.filter { !connectedInstitutions.contains($0) }
    }

    func balance(for category: AccountCategory) -> Decimal {
        snapshot.accounts
            .filter { $0.category == category }
            .reduce(0) { $0 + $1.balance }
    }

    func accounts(for category: AccountCategory) -> [FinancialAccount] {
        snapshot.accounts.filter { $0.category == category }
    }

    func connect(institution: InstitutionType) async {
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        do {
            guard let connector = connectors[institution] else { return }
            let newAccounts = try await connector.connect()
            var accounts = snapshot.accounts.filter { $0.institution != institution }
            accounts.append(contentsOf: newAccounts)
            updateSnapshot(accounts: accounts)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func disconnect(institution: InstitutionType) {
        let accounts = snapshot.accounts.filter { $0.institution != institution }
        updateSnapshot(accounts: accounts)
    }

    func refreshAll() async {
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        var refreshed: [FinancialAccount] = []

        for institution in connectedInstitutions {
            guard let connector = connectors[institution] else { continue }
            let institutionAccounts = snapshot.accounts.filter { $0.institution == institution }

            do {
                let updated = try await connector.refresh(accounts: institutionAccounts)
                refreshed.append(contentsOf: updated)
            } catch {
                refreshed.append(contentsOf: institutionAccounts)
                lastError = error.localizedDescription
            }
        }

        updateSnapshot(accounts: refreshed)
    }

    private func updateSnapshot(accounts: [FinancialAccount]) {
        let total = accounts.reduce(Decimal(0)) { $0 + $1.balance }
        snapshot = PortfolioSnapshot(
            accounts: accounts.sorted { $0.balance > $1.balance },
            totalBalance: total,
            lastUpdated: .now,
            currencyCode: "EUR"
        )
        saveToDisk()
        WidgetDataManager.shared.save(snapshot: snapshot)
    }

    private func loadFromDisk() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let accounts = try? JSONDecoder().decode([FinancialAccount].self, from: data),
              !accounts.isEmpty else {
            loadDemoData()
            return
        }
        let total = accounts.reduce(Decimal(0)) { $0 + $1.balance }
        snapshot = PortfolioSnapshot(
            accounts: accounts,
            totalBalance: total,
            lastUpdated: .now,
            currencyCode: "EUR"
        )
    }

    private func loadDemoData() {
        var accounts: [FinancialAccount] = []
        for institution in InstitutionType.allCases {
            accounts.append(contentsOf: MockInstitutionConnector.sampleAccounts(for: institution))
        }
        updateSnapshot(accounts: accounts)
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(snapshot.accounts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
