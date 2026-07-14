import SwiftUI
import Charts

struct AnalyticsView: View {
    @Environment(AggregationService.self) private var aggregation
    @Environment(AnalyticsService.self) private var analytics

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    PeriodPickerView(
                        selected: analytics.selectedPeriod,
                        onSelect: { analytics.setPeriod($0) }
                    )

                    if analytics.isLoading {
                        ProgressView("Analyse en cours…")
                            .frame(maxWidth: .infinity)
                            .padding()
                    }

                    InsightsCardsView(insights: analytics.insights)

                    SavingsProgressChartView(
                        data: analytics.savingsHistory,
                        currentTotal: aggregation.balance(for: .savings) + aggregation.balance(for: .lifeInsurance)
                    )

                    PatrimoineEvolutionChartView(data: analytics.patrimoineEvolution)

                    CashFlowChartView(data: analytics.monthlyCashFlow)

                    SpendingBreakdownChartView(summaries: analytics.spendingByCategory)

                    RecentTransactionsView(transactions: analytics.recentTransactions, accounts: aggregation.snapshot.accounts)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppColors.background)
            .navigationTitle("Analyses")
            .refreshable {
                await refresh()
            }
            .task {
                await refresh()
            }
            .onChange(of: aggregation.snapshot.lastUpdated) { _, _ in
                Task { await refresh() }
            }
        }
    }

    private func refresh() async {
        await analytics.refresh(
            accounts: aggregation.snapshot.accounts,
            powensService: aggregation.powensService
        )
    }
}

struct PeriodPickerView: View {
    let selected: AnalyticsService.AnalyticsPeriod
    let onSelect: (AnalyticsService.AnalyticsPeriod) -> Void

    var body: some View {
        HStack(spacing: 8) {
            ForEach(AnalyticsService.AnalyticsPeriod.allCases) { period in
                Button {
                    onSelect(period)
                } label: {
                    Text(period.rawValue)
                        .font(AppTypography.caption())
                        .fontWeight(selected == period ? .semibold : .regular)
                        .foregroundStyle(selected == period ? .white : AppColors.secondaryText)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(selected == period ? AppColors.accent : AppColors.cardBackground)
                        .clipShape(Capsule())
                        .shadow(color: selected == period ? .clear : AppColors.shadow, radius: 4, x: 0, y: 1)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct InsightsCardsView: View {
    let insights: SpendingInsights

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Vue d'ensemble")
                .font(AppTypography.headline())

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                InsightCard(
                    title: "Dépenses",
                    value: insights.totalExpenses,
                    subtitle: trendLabel(insights.monthOverMonthChange),
                    subtitleColor: insights.monthOverMonthChange > 0 ? AppColors.negative : AppColors.positive,
                    icon: "arrow.up.circle.fill"
                )
                InsightCard(
                    title: "Revenus",
                    value: insights.totalIncome,
                    subtitle: "sur la période",
                    subtitleColor: AppColors.secondaryText,
                    icon: "arrow.down.circle.fill"
                )
                InsightCard(
                    title: "Moy. / jour",
                    value: insights.averageDailySpending,
                    subtitle: "dépenses",
                    subtitleColor: AppColors.secondaryText,
                    icon: "calendar"
                )
                InsightCard(
                    title: "Taux d'épargne",
                    value: nil,
                    formattedValue: String(format: "%.0f %%", insights.savingsRate),
                    subtitle: insights.topCategory.map { "Top : \($0.rawValue)" } ?? "—",
                    subtitleColor: AppColors.accent,
                    icon: "percent"
                )
            }
        }
        .padding(20)
        .cardStyle()
    }

    private func trendLabel(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", change)) % vs période préc."
    }
}

struct InsightCard: View {
    let title: String
    var value: Decimal? = nil
    var formattedValue: String? = nil
    let subtitle: String
    let subtitleColor: Color
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.caption)
                    .foregroundStyle(AppColors.accent)
                Text(title)
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.secondaryText)
            }
            if let value {
                AmountText(amount: value, size: .small)
            } else if let formattedValue {
                Text(formattedValue)
                    .font(AppTypography.amount())
                    .foregroundStyle(AppColors.primaryText)
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(subtitleColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(AppColors.background)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct SavingsProgressChartView: View {
    let data: [SavingsDataPoint]
    let currentTotal: Decimal

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Progression épargne")
                        .font(AppTypography.headline())
                    Text("12 derniers mois")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.secondaryText)
                }
                Spacer()
                AmountText(amount: currentTotal, size: .small, color: AppColors.positive)
            }

            if data.isEmpty {
                EmptyChartPlaceholder(message: "Connectez un compte épargne")
            } else {
                Chart(data) { point in
                    AreaMark(
                        x: .value("Mois", point.month, unit: .month),
                        y: .value("Épargne", NSDecimalNumber(decimal: point.totalSavings).doubleValue)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [AppColors.positive.opacity(0.3), AppColors.positive.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )

                    LineMark(
                        x: .value("Mois", point.month, unit: .month),
                        y: .value("Épargne", NSDecimalNumber(decimal: point.totalSavings).doubleValue)
                    )
                    .foregroundStyle(AppColors.positive)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let doubleValue = value.as(Double.self) {
                                Text(formatCompact(doubleValue))
                            }
                        }
                    }
                }
                .frame(height: 200)
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct PatrimoineEvolutionChartView: View {
    let data: [PatrimoineEvolutionPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Évolution du patrimoine")
                .font(AppTypography.headline())

            if data.isEmpty {
                EmptyChartPlaceholder(message: "Aucune donnée disponible")
            } else {
                Chart(data) { point in
                    LineMark(
                        x: .value("Mois", point.month, unit: .month),
                        y: .value("Total", NSDecimalNumber(decimal: point.total).doubleValue)
                    )
                    .foregroundStyle(AppColors.accent)
                    .lineStyle(StrokeStyle(lineWidth: 2.5))

                    LineMark(
                        x: .value("Mois", point.month, unit: .month),
                        y: .value("Épargne", NSDecimalNumber(decimal: point.savings).doubleValue)
                    )
                    .foregroundStyle(AppColors.positive)
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))

                    LineMark(
                        x: .value("Mois", point.month, unit: .month),
                        y: .value("Investissements", NSDecimalNumber(decimal: point.investments).doubleValue)
                    )
                    .foregroundStyle(Color(hex: "8B5CF6"))
                    .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                }
                .chartForegroundStyleScale([
                    "Total": AppColors.accent,
                    "Épargne": AppColors.positive,
                    "Investissements": Color(hex: "8B5CF6")
                ])
                .chartXAxis {
                    AxisMarks(values: .stride(by: .month, count: 2)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatCompact(v))
                            }
                        }
                    }
                }
                .frame(height: 200)

                HStack(spacing: 16) {
                    ChartLegendItem(color: AppColors.accent, label: "Total")
                    ChartLegendItem(color: AppColors.positive, label: "Épargne")
                    ChartLegendItem(color: Color(hex: "8B5CF6"), label: "Investissements")
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct CashFlowChartView: View {
    let data: [MonthlyCashFlow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenus vs dépenses")
                .font(AppTypography.headline())

            if data.isEmpty {
                EmptyChartPlaceholder(message: "Aucune transaction")
            } else {
                Chart(data) { item in
                    BarMark(
                        x: .value("Mois", item.month, unit: .month),
                        y: .value("Montant", NSDecimalNumber(decimal: item.income).doubleValue)
                    )
                    .foregroundStyle(AppColors.positive)
                    .position(by: .value("Type", "Revenus"))

                    BarMark(
                        x: .value("Mois", item.month, unit: .month),
                        y: .value("Montant", NSDecimalNumber(decimal: item.expenses).doubleValue)
                    )
                    .foregroundStyle(AppColors.negative.opacity(0.8))
                    .position(by: .value("Type", "Dépenses"))
                }
                .chartXAxis {
                    AxisMarks { _ in
                        AxisValueLabel(format: .dateTime.month(.abbreviated))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let v = value.as(Double.self) {
                                Text(formatCompact(v))
                            }
                        }
                    }
                }
                .frame(height: 180)

                HStack(spacing: 16) {
                    ChartLegendItem(color: AppColors.positive, label: "Revenus")
                    ChartLegendItem(color: AppColors.negative.opacity(0.8), label: "Dépenses")
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct SpendingBreakdownChartView: View {
    let summaries: [SpendingCategorySummary]

    private var topCategories: [SpendingCategorySummary] {
        Array(summaries.filter { $0.category != .income && $0.category != .savings }.prefix(6))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dépenses par catégorie")
                .font(AppTypography.headline())

            if topCategories.isEmpty {
                EmptyChartPlaceholder(message: "Aucune dépense sur la période")
            } else {
                Chart(topCategories) { item in
                    SectorMark(
                        angle: .value("Montant", NSDecimalNumber(decimal: item.amount).doubleValue),
                        innerRadius: .ratio(0.55),
                        angularInset: 1.5
                    )
                    .foregroundStyle(Color(hex: item.category.colorHex))
                    .cornerRadius(4)
                }
                .frame(height: 180)

                VStack(spacing: 8) {
                    ForEach(topCategories) { item in
                        HStack(spacing: 10) {
                            Circle()
                                .fill(Color(hex: item.category.colorHex))
                                .frame(width: 10, height: 10)
                            Image(systemName: item.category.icon)
                                .font(.caption)
                                .foregroundStyle(AppColors.secondaryText)
                                .frame(width: 16)
                            Text(item.category.rawValue)
                                .font(AppTypography.body())
                            Spacer()
                            Text(String(format: "%.0f %%", item.percentage))
                                .font(AppTypography.caption())
                                .foregroundStyle(AppColors.secondaryText)
                            AmountText(amount: item.amount, size: .small)
                        }
                    }
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct RecentTransactionsView: View {
    let transactions: [Transaction]
    let accounts: [FinancialAccount]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Dernières opérations")
                .font(AppTypography.headline())

            if transactions.isEmpty {
                EmptyChartPlaceholder(message: "Aucune opération")
            } else {
                ForEach(transactions) { tx in
                    TransactionRowView(transaction: tx, account: accounts.first { $0.id == tx.accountId })
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct TransactionRowView: View {
    let transaction: Transaction
    let account: FinancialAccount?

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: transaction.category.colorHex).opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category.icon)
                    .font(.caption)
                    .foregroundStyle(Color(hex: transaction.category.colorHex))
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.label)
                    .font(AppTypography.headline())
                    .lineLimit(1)
                HStack(spacing: 4) {
                    Text(transaction.date.formatted(date: .abbreviated, time: .omitted))
                    if let account {
                        Text("·")
                        Text(account.institution.shortName)
                    }
                }
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            Text(formattedAmount)
                .font(AppTypography.smallAmount())
                .foregroundStyle(transaction.isIncome ? AppColors.positive : AppColors.primaryText)
        }
        .padding(.vertical, 4)
    }

    private var formattedAmount: String {
        let prefix = transaction.isIncome ? "+" : "−"
        let amount = transaction.amount.formatted(.currency(code: "EUR").locale(Locale(identifier: "fr_FR")))
        return "\(prefix)\(amount)"
    }
}

struct ChartLegendItem: View {
    let color: Color
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 8, height: 8)
            Text(label)
                .font(.caption2)
                .foregroundStyle(AppColors.secondaryText)
        }
    }
}

struct EmptyChartPlaceholder: View {
    let message: String

    var body: some View {
        Text(message)
            .font(AppTypography.caption())
            .foregroundStyle(AppColors.secondaryText)
            .frame(maxWidth: .infinity)
            .frame(height: 100)
    }
}

private func formatCompact(_ value: Double) -> String {
    if value >= 1_000_000 {
        return String(format: "%.1fM €", value / 1_000_000)
    }
    if value >= 1_000 {
        return String(format: "%.0fk €", value / 1_000)
    }
    return String(format: "%.0f €", value)
}
