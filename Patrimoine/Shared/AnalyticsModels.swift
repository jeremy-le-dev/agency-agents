import Foundation

enum SpendingCategory: String, Codable, CaseIterable, Identifiable {
    case groceries = "Alimentation"
    case housing = "Logement"
    case transport = "Transport"
    case leisure = "Loisirs"
    case health = "Santé"
    case shopping = "Shopping"
    case subscriptions = "Abonnements"
    case income = "Revenus"
    case savings = "Épargne"
    case other = "Autres"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .groceries: return "cart.fill"
        case .housing: return "house.fill"
        case .transport: return "car.fill"
        case .leisure: return "gamecontroller.fill"
        case .health: return "heart.fill"
        case .shopping: return "bag.fill"
        case .subscriptions: return "repeat"
        case .income: return "arrow.down.circle.fill"
        case .savings: return "banknote.fill"
        case .other: return "ellipsis.circle.fill"
        }
    }

    var colorHex: String {
        switch self {
        case .groceries: return "10B981"
        case .housing: return "6366F1"
        case .transport: return "F59E0B"
        case .leisure: return "EC4899"
        case .health: return "EF4444"
        case .shopping: return "8B5CF6"
        case .subscriptions: return "3B82F6"
        case .income: return "22C55E"
        case .savings: return "14B8A6"
        case .other: return "9CA3AF"
        }
    }
}

struct Transaction: Identifiable, Codable, Hashable {
    let id: UUID
    var label: String
    var amount: Decimal
    var date: Date
    var category: SpendingCategory
    var accountId: UUID
    var isIncome: Bool

    init(
        id: UUID = UUID(),
        label: String,
        amount: Decimal,
        date: Date,
        category: SpendingCategory,
        accountId: UUID,
        isIncome: Bool = false
    ) {
        self.id = id
        self.label = label
        self.amount = amount
        self.date = date
        self.category = category
        self.accountId = accountId
        self.isIncome = isIncome
    }
}

struct SavingsDataPoint: Identifiable, Codable, Hashable {
    let id: UUID
    let month: Date
    let totalSavings: Decimal
    let monthlyContribution: Decimal

    init(id: UUID = UUID(), month: Date, totalSavings: Decimal, monthlyContribution: Decimal) {
        self.id = id
        self.month = month
        self.totalSavings = totalSavings
        self.monthlyContribution = monthlyContribution
    }
}

struct MonthlyCashFlow: Identifiable, Codable, Hashable {
    let id: UUID
    let month: Date
    let income: Decimal
    let expenses: Decimal

    var net: Decimal { income - expenses }
    var savingsRate: Double {
        guard income > 0 else { return 0 }
        return NSDecimalNumber(decimal: net / income).doubleValue * 100
    }

    init(id: UUID = UUID(), month: Date, income: Decimal, expenses: Decimal) {
        self.id = id
        self.month = month
        self.income = income
        self.expenses = expenses
    }
}

struct SpendingCategorySummary: Identifiable, Hashable {
    let category: SpendingCategory
    let amount: Decimal
    let percentage: Double
    let transactionCount: Int

    var id: String { category.id }
}

struct SpendingInsights: Hashable {
    let totalExpenses: Decimal
    let totalIncome: Decimal
    let monthOverMonthChange: Double
    let topCategory: SpendingCategory?
    let averageDailySpending: Decimal
    let savingsRate: Double

    static let empty = SpendingInsights(
        totalExpenses: 0,
        totalIncome: 0,
        monthOverMonthChange: 0,
        topCategory: nil,
        averageDailySpending: 0,
        savingsRate: 0
    )
}

struct PatrimoineEvolutionPoint: Identifiable, Hashable {
    let id: UUID
    let month: Date
    let total: Decimal
    let savings: Decimal
    let investments: Decimal

    init(id: UUID = UUID(), month: Date, total: Decimal, savings: Decimal, investments: Decimal) {
        self.id = id
        self.month = month
        self.total = total
        self.savings = savings
        self.investments = investments
    }
}
