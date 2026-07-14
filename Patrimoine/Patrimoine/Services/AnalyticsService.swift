import Foundation
import Observation

@MainActor
@Observable
final class AnalyticsService {
    private(set) var savingsHistory: [SavingsDataPoint] = []
    private(set) var patrimoineEvolution: [PatrimoineEvolutionPoint] = []
    private(set) var spendingByCategory: [SpendingCategorySummary] = []
    private(set) var monthlyCashFlow: [MonthlyCashFlow] = []
    private(set) var recentTransactions: [Transaction] = []
    private(set) var insights: SpendingInsights = .empty
    private(set) var selectedPeriod: AnalyticsPeriod = .month
    private(set) var isLoading = false

    private var allTransactions: [Transaction] = []
    private let storageKey = "patrimoine.transactions"

    enum AnalyticsPeriod: String, CaseIterable, Identifiable {
        case month = "Ce mois"
        case quarter = "3 mois"
        case semester = "6 mois"

        var id: String { rawValue }

        var monthCount: Int {
            switch self {
            case .month: return 1
            case .quarter: return 3
            case .semester: return 6
            }
        }
    }

    func setPeriod(_ period: AnalyticsPeriod) {
        selectedPeriod = period
        recompute()
    }

    func refresh(accounts: [FinancialAccount], powensService: PowensService?) async {
        isLoading = true
        defer { isLoading = false }

        if let powensService, powensService.isConfigured, powensService.hasAuthToken {
            do {
                let powensTransactions = try await powensService.fetchTransactions(accountIds: accounts)
                if !powensTransactions.isEmpty {
                    allTransactions = powensTransactions
                    saveTransactions()
                }
            } catch {
                // Fallback sur données locales / mock
            }
        }

        if allTransactions.isEmpty {
            allTransactions = loadTransactions() ?? MockAnalyticsData.generateTransactions(for: accounts)
            saveTransactions()
        }

        savingsHistory = MockAnalyticsData.generateSavingsHistory(accounts: accounts)
        patrimoineEvolution = MockAnalyticsData.generatePatrimoineEvolution(accounts: accounts)
        recompute()
    }

    private func recompute() {
        let calendar = Calendar.current
        let now = Date()
        guard let periodStart = calendar.date(byAdding: .month, value: -selectedPeriod.monthCount, to: now) else { return }

        let periodTransactions = allTransactions.filter { $0.date >= periodStart }
        let expenses = periodTransactions.filter { !$0.isIncome && $0.category != .income && $0.category != .savings }
        let income = periodTransactions.filter { $0.isIncome || $0.category == .income }

        let totalExpenses = expenses.reduce(Decimal(0)) { $0 + $1.amount }
        let totalIncome = income.reduce(Decimal(0)) { $0 + $1.amount }

        spendingByCategory = computeCategorySummaries(expenses: expenses, total: totalExpenses)
        monthlyCashFlow = computeMonthlyCashFlow(transactions: periodTransactions, months: selectedPeriod.monthCount)
        recentTransactions = Array(periodTransactions.prefix(15))
        insights = computeInsights(
            expenses: expenses,
            totalExpenses: totalExpenses,
            totalIncome: totalIncome,
            periodStart: periodStart,
            topCategory: spendingByCategory.first?.category
        )
    }

    private func computeCategorySummaries(expenses: [Transaction], total: Decimal) -> [SpendingCategorySummary] {
        let grouped = Dictionary(grouping: expenses, by: \.category)
        return grouped.map { category, txs in
            let amount = txs.reduce(Decimal(0)) { $0 + $1.amount }
            let pct = total > 0 ? NSDecimalNumber(decimal: amount / total).doubleValue * 100 : 0
            return SpendingCategorySummary(category: category, amount: amount, percentage: pct, transactionCount: txs.count)
        }
        .sorted { $0.amount > $1.amount }
    }

    private func computeMonthlyCashFlow(transactions: [Transaction], months: Int) -> [MonthlyCashFlow] {
        let calendar = Calendar.current
        let now = Date()
        var result: [MonthlyCashFlow] = []

        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let month = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
            guard let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) else { continue }

            let monthTxs = transactions.filter { $0.date >= monthStart && $0.date < monthEnd }
            let income = monthTxs.filter { $0.isIncome || $0.category == .income }.reduce(Decimal(0)) { $0 + $1.amount }
            let expenses = monthTxs.filter { !$0.isIncome && $0.category != .income }.reduce(Decimal(0)) { $0 + $1.amount }

            result.append(MonthlyCashFlow(month: monthStart, income: income, expenses: expenses))
        }

        return result
    }

    private func computeInsights(
        expenses: [Transaction],
        totalExpenses: Decimal,
        totalIncome: Decimal,
        periodStart: Date,
        topCategory: SpendingCategory?
    ) -> SpendingInsights {
        let calendar = Calendar.current
        let previousStart = calendar.date(byAdding: .month, value: -selectedPeriod.monthCount, to: periodStart) ?? periodStart
        let previousExpenses = allTransactions
            .filter { $0.date >= previousStart && $0.date < periodStart && !$0.isIncome }
            .reduce(Decimal(0)) { $0 + $1.amount }

        let momChange: Double = {
            guard previousExpenses > 0 else { return 0 }
            let diff = totalExpenses - previousExpenses
            return NSDecimalNumber(decimal: diff / previousExpenses).doubleValue * 100
        }()

        let days = max(1, calendar.dateComponents([.day], from: periodStart, to: Date()).day ?? 1)
        let avgDaily = totalExpenses / Decimal(days)
        let savingsRate = totalIncome > 0
            ? NSDecimalNumber(decimal: (totalIncome - totalExpenses) / totalIncome).doubleValue * 100
            : 0

        return SpendingInsights(
            totalExpenses: totalExpenses,
            totalIncome: totalIncome,
            monthOverMonthChange: momChange,
            topCategory: topCategory,
            averageDailySpending: avgDaily,
            savingsRate: max(0, savingsRate)
        )
    }

    private func loadTransactions() -> [Transaction]? {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let txs = try? JSONDecoder().decode([Transaction].self, from: data) else { return nil }
        return txs
    }

    private func saveTransactions() {
        guard let data = try? JSONEncoder().encode(allTransactions) else { return }
        UserDefaults.standard.set(data, forKey: storageKey)
    }
}
