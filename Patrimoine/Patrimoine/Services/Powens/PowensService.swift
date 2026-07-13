import Foundation
import Observation

@MainActor
@Observable
final class PowensService {
    private(set) var isConfigured = false
    private(set) var hasAuthToken = false
    private(set) var isConnecting = false
    private(set) var lastError: String?

    private let config: PowensConfig
    private let apiClient: PowensAPIClient
    private static let authTokenKey = "powens.auth_token"

    init(config: PowensConfig = .load()) {
        self.config = config
        self.apiClient = PowensAPIClient(config: config)
        self.isConfigured = config.isConfigured
        self.hasAuthToken = KeychainHelper.load(forKey: Self.authTokenKey) != nil
    }

    func ensureUserInitialized() async throws {
        guard config.isConfigured else { throw PowensError.notConfigured }

        if let existing = KeychainHelper.load(forKey: Self.authTokenKey), !existing.isEmpty {
            hasAuthToken = true
            return
        }

        guard config.canInitUser else {
            throw PowensError.notConfigured
        }

        let token = try await apiClient.initUser()
        KeychainHelper.save(token, forKey: Self.authTokenKey)
        hasAuthToken = true
    }

    func buildConnectURL() async throws -> URL {
        try await ensureUserInitialized()
        guard let authToken = KeychainHelper.load(forKey: Self.authTokenKey) else {
            throw PowensError.noAuthToken
        }
        let code = try await apiClient.temporaryCode(authToken: authToken)
        return apiClient.buildConnectURL(temporaryCode: code)
    }

    func handleCallback(url: URL) throws -> Int? {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            throw PowensError.invalidResponse
        }

        if let error = components.queryItems?.first(where: { $0.name == "error" })?.value {
            let description = components.queryItems?.first(where: { $0.name == "error_description" })?.value ?? error
            throw PowensError.connectionFailed(description)
        }

        guard let connectionIdString = components.queryItems?.first(where: { $0.name == "connection_id" })?.value,
              let connectionId = Int(connectionIdString) else {
            return nil
        }
        return connectionId
    }

    func fetchAllAccounts() async throws -> [FinancialAccount] {
        try await ensureUserInitialized()
        guard let authToken = KeychainHelper.load(forKey: Self.authTokenKey) else {
            throw PowensError.noAuthToken
        }

        let powensAccounts = try await apiClient.fetchAccounts(authToken: authToken)
        let connections = try await apiClient.fetchConnections(authToken: authToken)
        let connectorNames = Dictionary(uniqueKeysWithValues: connections.compactMap { conn -> (Int, String)? in
            guard let id = conn.idConnector, let name = conn.connectorName else { return nil }
            return (id, name)
        })

        return powensAccounts.compactMap { account in
            mapAccount(account, connectorNames: connectorNames)
        }
    }

    func fetchAccounts(for institution: InstitutionType) async throws -> [FinancialAccount] {
        let all = try await fetchAllAccounts()
        return all.filter { $0.institution == institution }
    }

    func fetchTransactions(accountIds: [FinancialAccount]) async throws -> [Transaction] {
        try await ensureUserInitialized()
        guard let authToken = KeychainHelper.load(forKey: Self.authTokenKey) else {
            throw PowensError.noAuthToken
        }

        let accountMap = Dictionary(uniqueKeysWithValues: accountIds.compactMap { account -> (String, FinancialAccount)? in
            guard let externalId = account.externalId else { return nil }
            return (externalId, account)
        })

        let powensTransactions = try await apiClient.fetchTransactions(authToken: authToken)
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate, .withDashSeparatorInDate]

        return powensTransactions.compactMap { tx in
            guard let idAccount = tx.idAccount,
                  let account = accountMap["\(idAccount)"],
                  let value = tx.value else { return nil }

            let isIncome = value > 0
            let date: Date = {
                if let dateStr = tx.date, let parsed = formatter.date(from: dateStr) { return parsed }
                return .now
            }()

            return Transaction(
                id: stableUUID(for: tx.id),
                label: tx.wording ?? "Opération",
                amount: Decimal(abs(value)),
                date: date,
                category: categorize(wording: tx.wording ?? "", isIncome: isIncome),
                accountId: account.id,
                isIncome: isIncome
            )
        }
    }

    func disconnect() {
        KeychainHelper.delete(forKey: Self.authTokenKey)
        hasAuthToken = false
    }

    private func mapAccount(_ account: PowensAccount, connectorNames: [Int: String]) -> FinancialAccount? {
        let connectorName = account.idConnector.flatMap { connectorNames[$0] } ?? ""
        guard let institution = InstitutionType.fromPowensConnector(name: connectorName) else {
            return nil
        }

        let category = mapCategory(accountType: account.type, institution: institution)
        let maskedNumber: String? = {
            if let iban = account.iban, iban.count >= 4 {
                return "•••• \(iban.suffix(4))"
            }
            if let number = account.number, number.count >= 4 {
                return "•••• \(number.suffix(4))"
            }
            return nil
        }()

        return FinancialAccount(
            id: stableUUID(for: account.id),
            name: account.name ?? "Compte",
            institution: institution,
            category: category,
            balance: Decimal(account.balance ?? 0),
            currencyCode: account.currency?.id ?? "EUR",
            lastSyncedAt: .now,
            isConnected: true,
            accountNumberMasked: maskedNumber,
            externalId: "\(account.id)",
            powensConnectionId: account.idConnection,
            dataSource: .powens
        )
    }

    private func mapCategory(accountType: String?, institution: InstitutionType) -> AccountCategory {
        switch accountType?.lowercased() {
        case "checking", "card": return .checking
        case "savings", "deposit": return .savings
        case "life_insurance", "insurance": return .lifeInsurance
        case "market", "pea", "per", "cto", "investment": return .investment
        default: return institution.defaultCategory
        }
    }

    private func stableUUID(for powensId: Int) -> UUID {
        let hex = String(format: "%012x", powensId)
        return UUID(uuidString: "00000000-0000-4000-8000-\(hex)") ?? UUID()
    }

    private func categorize(wording: String, isIncome: Bool) -> SpendingCategory {
        if isIncome { return .income }
        let text = wording.lowercased()
        if text.contains("carrefour") || text.contains("monoprix") || text.contains("leclerc") || text.contains("auchan") { return .groceries }
        if text.contains("loyer") || text.contains("edf") || text.contains("engie") || text.contains("rent") { return .housing }
        if text.contains("sncf") || text.contains("uber") || text.contains("total") || text.contains("essence") { return .transport }
        if text.contains("netflix") || text.contains("spotify") || text.contains("abonnement") { return .subscriptions }
        if text.contains("amazon") || text.contains("fnac") || text.contains("zara") { return .shopping }
        if text.contains("pharma") || text.contains("docteur") || text.contains("mutuelle") { return .health }
        if text.contains("restaurant") || text.contains("cinema") || text.contains("bar") { return .leisure }
        return .other
    }
}

extension InstitutionType {
    static func fromPowensConnector(name: String) -> InstitutionType? {
        let normalized = name.lowercased()
        return InstitutionType.allCases.first { institution in
            institution.powensKeywords.contains { normalized.contains($0) }
        }
    }
}
