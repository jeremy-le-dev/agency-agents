import Foundation

enum MockAnalyticsData {
    static func generateTransactions(for accounts: [FinancialAccount]) -> [Transaction] {
        let checkingAccounts = accounts.filter { $0.category == .checking }
        guard !checkingAccounts.isEmpty else { return [] }

        var transactions: [Transaction] = []
        let calendar = Calendar.current
        let now = Date()

        let expenseTemplates: [(String, SpendingCategory, ClosedRange<Double>)] = [
            ("Carrefour", .groceries, 35...120),
            ("Monoprix", .groceries, 25...80),
            ("Loyer", .housing, 800...1200),
            ("EDF", .housing, 60...150),
            ("SNCF", .transport, 15...85),
            ("Total Energies", .transport, 40...90),
            ("Netflix", .subscriptions, 13...16),
            ("Spotify", .subscriptions, 10...12),
            ("Amazon", .shopping, 20...150),
            ("Pharmacie", .health, 15...60),
            ("Restaurant", .leisure, 25...80),
            ("Cinéma", .leisure, 12...25),
            ("Fnac", .shopping, 30...200),
            ("Uber", .transport, 8...35),
        ]

        for monthOffset in 0..<6 {
            guard let monthStart = calendar.date(byAdding: .month, value: -monthOffset, to: now) else { continue }

            for account in checkingAccounts {
                if let salary = makeSalary(for: account, month: monthStart) {
                    transactions.append(salary)
                }

                let expenseCount = Int.random(in: 18...32)
                for _ in 0..<expenseCount {
                    let template = expenseTemplates.randomElement()!
                    let day = Int.random(in: 1...28)
                    var components = calendar.dateComponents([.year, .month], from: monthStart)
                    components.day = day
                    guard let date = calendar.date(from: components) else { continue }

                    let amount = Decimal(Double.random(in: template.2))
                    transactions.append(Transaction(
                        label: template.0,
                        amount: amount,
                        date: date,
                        category: template.1,
                        accountId: account.id
                    ))
                }
            }
        }

        return transactions.sorted { $0.date > $1.date }
    }

    static func generateSavingsHistory(
        accounts: [FinancialAccount],
        months: Int = 12
    ) -> [SavingsDataPoint] {
        let savingsAccounts = accounts.filter { $0.category == .savings || $0.category == .lifeInsurance }
        let currentTotal = savingsAccounts.reduce(Decimal(0)) { $0 + $1.balance }
        guard currentTotal > 0 else { return [] }

        let calendar = Calendar.current
        let now = Date()
        var points: [SavingsDataPoint] = []
        var runningTotal = currentTotal * 0.72

        for offset in stride(from: months - 1, through: 0, by: -1) {
            guard let month = calendar.date(byAdding: .month, value: -offset, to: now) else { continue }
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month

            let growthFactor = Decimal(1 + Double(months - offset) * 0.025)
            let target = currentTotal * growthFactor / Decimal(1 + Double(months) * 0.025)
            let contribution = max(0, target - runningTotal)
            runningTotal = min(currentTotal, runningTotal + contribution)

            points.append(SavingsDataPoint(
                month: monthStart,
                totalSavings: runningTotal,
                monthlyContribution: contribution
            ))
        }

        if var last = points.last {
            last = SavingsDataPoint(month: last.month, totalSavings: currentTotal, monthlyContribution: last.monthlyContribution)
            points[points.count - 1] = last
        }

        return points
    }

    static func generatePatrimoineEvolution(
        accounts: [FinancialAccount],
        months: Int = 12
    ) -> [PatrimoineEvolutionPoint] {
        let currentTotal = accounts.reduce(Decimal(0)) { $0 + $1.balance }
        let currentSavings = accounts
            .filter { $0.category == .savings || $0.category == .lifeInsurance }
            .reduce(Decimal(0)) { $0 + $1.balance }
        let currentInvestments = accounts
            .filter { $0.category == .investment }
            .reduce(Decimal(0)) { $0 + $1.balance }

        guard currentTotal > 0 else { return [] }

        let calendar = Calendar.current
        let now = Date()
        var points: [PatrimoineEvolutionPoint] = []

        for offset in 0..<months {
            guard let month = calendar.date(byAdding: .month, value: -(months - 1 - offset), to: now) else { continue }
            let monthStart = calendar.date(from: calendar.dateComponents([.year, .month], from: month)) ?? month
            let progress = Decimal(offset + 1) / Decimal(months)
            let noise = Decimal(Double.random(in: 0.96...1.02))

            points.append(PatrimoineEvolutionPoint(
                month: monthStart,
                total: currentTotal * progress * noise,
                savings: currentSavings * progress * noise,
                investments: currentInvestments * progress * noise
            ))
        }

        return points
    }

    private static func makeSalary(for account: FinancialAccount, month: Date) -> Transaction? {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month], from: month)
        components.day = 28
        guard let date = calendar.date(from: components) else { return nil }

        return Transaction(
            label: "Salaire",
            amount: Decimal(Double.random(in: 2400...3200)),
            date: date,
            category: .income,
            accountId: account.id,
            isIncome: true
        )
    }
}
