import Foundation
import Observation

@MainActor
@Observable
final class AggregationService {
    private(set) var snapshot: PortfolioSnapshot = .empty
    private(set) var isSyncing = false
    private(set) var lastError: String?
    private(set) var powensConnectURL: URL?
    var showPowensConnect = false

    let powensService = PowensService()
    private let storageKey = "patrimoine.accounts"
    private let useDemoDataKey = "patrimoine.useDemoData"
    private var connectors: [InstitutionType: InstitutionConnector] = [:]

    var usesPowens: Bool { powensService.isConfigured }

    init() {
        configureConnectors()
        loadFromDisk()
        WidgetDataManager.shared.save(snapshot: snapshot)
    }

    private func configureConnectors() {
        for institution in InstitutionType.allCases {
            connectors[institution] = MockInstitutionConnector(institution: institution)
        }
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

        if powensService.isConfigured {
            do {
                let url = try await powensService.buildConnectURL()
                powensConnectURL = url
                showPowensConnect = true
            } catch {
                lastError = error.localizedDescription
            }
            return
        }

        do {
            guard let connector = connectors[institution] else { return }
            let newAccounts = try await connector.connect()
            var accounts = snapshot.accounts.filter { $0.institution != institution }
            accounts.append(contentsOf: newAccounts)
            UserDefaults.standard.set(false, forKey: useDemoDataKey)
            updateSnapshot(accounts: accounts)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func completePowensConnection() async {
        isSyncing = true
        lastError = nil
        defer {
            isSyncing = false
            showPowensConnect = false
            powensConnectURL = nil
        }

        do {
            let powensAccounts = try await powensService.fetchAllAccounts()
            var accounts = snapshot.accounts.filter { $0.dataSource != .powens }
            accounts.append(contentsOf: powensAccounts)
            UserDefaults.standard.set(false, forKey: useDemoDataKey)
            updateSnapshot(accounts: accounts)
        } catch {
            lastError = error.localizedDescription
        }
    }

    func reportError(_ message: String?) {
        lastError = message
    }

    func cancelPowensConnection() {
        showPowensConnect = false
        powensConnectURL = nil
    }

    func disconnect(institution: InstitutionType) {
        let accounts = snapshot.accounts.filter { $0.institution != institution }
        updateSnapshot(accounts: accounts)
    }

    func refreshAll() async {
        isSyncing = true
        lastError = nil
        defer { isSyncing = false }

        if powensService.isConfigured && powensService.hasAuthToken {
            do {
                let powensAccounts = try await powensService.fetchAllAccounts()
                var accounts = snapshot.accounts.filter { $0.dataSource != .powens }
                accounts.append(contentsOf: powensAccounts)
                updateSnapshot(accounts: accounts)
                return
            } catch {
                lastError = error.localizedDescription
            }
        }

        var refreshed: [FinancialAccount] = []

        for institution in connectedInstitutions {
            let institutionAccounts = snapshot.accounts.filter { $0.institution == institution }
            guard let connector = connectors[institution] else {
                refreshed.append(contentsOf: institutionAccounts)
                continue
            }

            if institutionAccounts.allSatisfy({ $0.dataSource == .powens }) {
                continue
            }

            do {
                let updated = try await connector.refresh(accounts: institutionAccounts)
                refreshed.append(contentsOf: updated)
            } catch {
                refreshed.append(contentsOf: institutionAccounts)
                lastError = error.localizedDescription
            }
        }

        let powensExisting = snapshot.accounts.filter { $0.dataSource == .powens }
        refreshed.append(contentsOf: powensExisting)
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
            if !UserDefaults.standard.bool(forKey: useDemoDataKey) && powensService.isConfigured {
                snapshot = .empty
                return
            }
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
        UserDefaults.standard.set(true, forKey: useDemoDataKey)
        updateSnapshot(accounts: accounts)
    }

    private func saveToDisk() {
        guard let data = try? JSONEncoder().encode(snapshot.accounts) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
