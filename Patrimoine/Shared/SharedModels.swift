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

    /// Mots-clés pour mapper les connecteurs Powens au type d'établissement.
    var powensKeywords: [String] {
        switch self {
        case .creditAgricole: return ["crédit agricole", "credit agricole", "caisse régionale"]
        case .tradeRepublic: return ["trade republic", "traderepublic"]
        case .amundi: return ["amundi"]
        case .linxea: return ["linxea"]
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
    var externalId: String?
    var powensConnectionId: Int?
    var dataSource: AccountDataSource

    init(
        id: UUID = UUID(),
        name: String,
        institution: InstitutionType,
        category: AccountCategory,
        balance: Decimal,
        currencyCode: String,
        lastSyncedAt: Date,
        isConnected: Bool,
        accountNumberMasked: String? = nil,
        externalId: String? = nil,
        powensConnectionId: Int? = nil,
        dataSource: AccountDataSource = .mock
    ) {
        self.id = id
        self.name = name
        self.institution = institution
        self.category = category
        self.balance = balance
        self.currencyCode = currencyCode
        self.lastSyncedAt = lastSyncedAt
        self.isConnected = isConnected
        self.accountNumberMasked = accountNumberMasked
        self.externalId = externalId
        self.powensConnectionId = powensConnectionId
        self.dataSource = dataSource
    }

    enum CodingKeys: String, CodingKey {
        case id, name, institution, category, balance, currencyCode
        case lastSyncedAt, isConnected, accountNumberMasked
        case externalId, powensConnectionId, dataSource
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        institution = try container.decode(InstitutionType.self, forKey: .institution)
        category = try container.decode(AccountCategory.self, forKey: .category)
        balance = try container.decode(Decimal.self, forKey: .balance)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        lastSyncedAt = try container.decode(Date.self, forKey: .lastSyncedAt)
        isConnected = try container.decode(Bool.self, forKey: .isConnected)
        accountNumberMasked = try container.decodeIfPresent(String.self, forKey: .accountNumberMasked)
        externalId = try container.decodeIfPresent(String.self, forKey: .externalId)
        powensConnectionId = try container.decodeIfPresent(Int.self, forKey: .powensConnectionId)
        dataSource = try container.decodeIfPresent(AccountDataSource.self, forKey: .dataSource) ?? .mock
    }
}

enum AccountDataSource: String, Codable {
    case mock
    case powens
}

extension FinancialAccount {
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
