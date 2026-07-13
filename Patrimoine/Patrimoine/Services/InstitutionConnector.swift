import Foundation

protocol InstitutionConnector: Sendable {
    var institution: InstitutionType { get }
    func connect() async throws -> [FinancialAccount]
    func refresh(accounts: [FinancialAccount]) async throws -> [FinancialAccount]
}

enum ConnectorError: LocalizedError {
    case notImplemented
    case authenticationRequired
    case networkFailure
    case powensRequired

    var errorDescription: String? {
        switch self {
        case .notImplemented:
            return "Connexion non encore disponible pour cet établissement."
        case .authenticationRequired:
            return "Authentification requise. Veuillez vous reconnecter."
        case .networkFailure:
            return "Impossible de synchroniser vos comptes. Réessayez plus tard."
        case .powensRequired:
            return "Connexion via Powens requise."
        }
    }
}

struct MockInstitutionConnector: InstitutionConnector {
    let institution: InstitutionType

    func connect() async throws -> [FinancialAccount] {
        try await Task.sleep(nanoseconds: 800_000_000)
        return Self.sampleAccounts(for: institution)
    }

    func refresh(accounts: [FinancialAccount]) async throws -> [FinancialAccount] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return accounts.map { account in
            var updated = account
            let variation = Decimal(Double.random(in: -0.02...0.03))
            updated.balance = max(0, account.balance * (1 + variation))
            updated.lastSyncedAt = .now
            return updated
        }
    }

    static func sampleAccounts(for institution: InstitutionType) -> [FinancialAccount] {
        switch institution {
        case .creditAgricole:
            return [
                FinancialAccount(
                    name: "Compte courant",
                    institution: .creditAgricole,
                    category: .checking,
                    balance: 4_832.47,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true,
                    accountNumberMasked: "•••• 4821"
                ),
                FinancialAccount(
                    name: "Livret A",
                    institution: .creditAgricole,
                    category: .savings,
                    balance: 12_500.00,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true,
                    accountNumberMasked: "•••• 9103"
                ),
                FinancialAccount(
                    name: "LDDS",
                    institution: .creditAgricole,
                    category: .savings,
                    balance: 8_200.00,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true,
                    accountNumberMasked: "•••• 3378"
                )
            ]
        case .tradeRepublic:
            return [
                FinancialAccount(
                    name: "Portefeuille actions",
                    institution: .tradeRepublic,
                    category: .investment,
                    balance: 18_945.32,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true
                ),
                FinancialAccount(
                    name: "Compte espèces",
                    institution: .tradeRepublic,
                    category: .checking,
                    balance: 1_240.00,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true
                )
            ]
        case .amundi:
            return [
                FinancialAccount(
                    name: "PEA Amundi",
                    institution: .amundi,
                    category: .investment,
                    balance: 34_210.88,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true
                ),
                FinancialAccount(
                    name: "Assurance vie Amundi",
                    institution: .amundi,
                    category: .lifeInsurance,
                    balance: 22_500.00,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true
                )
            ]
        case .linxea:
            return [
                FinancialAccount(
                    name: "Linxea Spirit 2",
                    institution: .linxea,
                    category: .lifeInsurance,
                    balance: 45_680.15,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true
                ),
                FinancialAccount(
                    name: "Linxea Avenir 2",
                    institution: .linxea,
                    category: .lifeInsurance,
                    balance: 15_320.00,
                    currencyCode: "EUR",
                    lastSyncedAt: .now,
                    isConnected: true
                )
            ]
        }
    }
}