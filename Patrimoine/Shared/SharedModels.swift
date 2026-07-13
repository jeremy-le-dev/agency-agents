import Foundation

enum AccountCategory: String, Codable, CaseIterable, Identifiable {
    case checking = "Comptes courants"
    case savings = "Épargne"
    case investment = "Investissements"
    case lifeInsurance = "Assurance vie"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .checking: return "creditcard.fill"
        case .savings: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .lifeInsurance: return "shield.fill"
        }
    }
}

enum InstitutionType: String, Codable, CaseIterable, Identifiable {
    case creditAgricole = "Crédit Agricole"
    case tradeRepublic = "Trade Republic"
    case amundi = "Amundi"
    case linxea = "Linxea"

    var id: String { rawValue }

    var shortName: String {
        switch self {
        case .creditAgricole: return "CA"
        case .tradeRepublic: return "TR"
        case .amundi: return "AM"
        case .linxea: return "LX"
        }
    }

    var brandColorHex: String {
        switch self {
        case .creditAgricole: return "00A651"
        case .tradeRepublic: return "1A1A1A"
        case .amundi: return "003DA5"
        case .linxea: return "E85D3B"
        }
    }

    var defaultCategory: AccountCategory {
        switch self {
        case .creditAgricole: return .checking
        case .tradeRepublic, .amundi: return .investment
        case .linxea: return .lifeInsurance
        }
    }
}

struct FinancialAccount: Identifiable, Codable, Hashable {
    let id: UUID
    var name: String
    var institution: InstitutionType
    var category: AccountCategory
    var balance: Decimal
    var currencyCode: String
    var lastSyncedAt: Date
    var isConnected: Bool
    var accountNumberMasked: String?

    var formattedBalance: String {
        balance.formatted(.currency(code: currencyCode).locale(Locale(identifier: "fr_FR")))
    }
}

struct PortfolioSnapshot: Codable {
    var accounts: [FinancialAccount]
    var totalBalance: Decimal
    var lastUpdated: Date
    var currencyCode: String

    static let empty = PortfolioSnapshot(
        accounts: [],
        totalBalance: 0,
        lastUpdated: .now,
        currencyCode: "EUR"
    )
}

struct WidgetAccountSummary: Codable, Identifiable {
    let id: UUID
    let name: String
    let institution: String
    let balance: Double
    let colorHex: String
}

struct WidgetSnapshot: Codable {
    let totalBalance: Double
    let currencyCode: String
    let lastUpdated: Date
    let topAccounts: [WidgetAccountSummary]
}
