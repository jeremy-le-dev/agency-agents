import SwiftUI

struct BalanceHeaderView: View {
    let totalBalance: Decimal
    let lastUpdated: Date
    let isSyncing: Bool
    let onRefresh: () -> Void

    @State private var isBalanceHidden = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Patrimoine total")
                    .font(AppTypography.body())
                    .foregroundStyle(AppColors.secondaryText)

                Spacer()

                Button {
                    isBalanceHidden.toggle()
                } label: {
                    Image(systemName: isBalanceHidden ? "eye.slash" : "eye")
                        .font(.body)
                        .foregroundStyle(AppColors.secondaryText)
                }

                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.body)
                        .foregroundStyle(AppColors.accent)
                        .rotationEffect(.degrees(isSyncing ? 360 : 0))
                        .animation(isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: isSyncing)
                }
                .disabled(isSyncing)
            }

            if isBalanceHidden {
                Text("••••••")
                    .font(AppTypography.largeTitle())
                    .foregroundStyle(AppColors.primaryText)
            } else {
                AmountText(amount: totalBalance, size: .large)
            }

            SyncStatusView(lastUpdated: lastUpdated, isSyncing: isSyncing)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

struct CategoryBreakdownView: View {
    let categories: [(AccountCategory, Decimal)]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Répartition")
                .font(AppTypography.headline())
                .foregroundStyle(AppColors.primaryText)

            HStack(spacing: 10) {
                ForEach(categories, id: \.0) { category, balance in
                    VStack(alignment: .leading, spacing: 6) {
                        Image(systemName: category.icon)
                            .font(.caption)
                            .foregroundStyle(AppColors.accent)
                        Text(category.rawValue)
                            .font(.caption2)
                            .foregroundStyle(AppColors.secondaryText)
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                        AmountText(amount: balance, size: .small)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(12)
                    .background(AppColors.background)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
        .padding(20)
        .cardStyle()
    }
}

struct InstitutionCardView: View {
    let institution: InstitutionType
    let accounts: [FinancialAccount]
    let total: Decimal

    var body: some View {
        NavigationLink {
            InstitutionDetailView(institution: institution, accounts: accounts)
        } label: {
            HStack(spacing: 14) {
                InstitutionLogoView(institution: institution)

                VStack(alignment: .leading, spacing: 4) {
                    Text(institution.rawValue)
                        .font(AppTypography.headline())
                        .foregroundStyle(AppColors.primaryText)

                    Text("\(accounts.count) compte\(accounts.count > 1 ? "s" : "")")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.secondaryText)
                }

                Spacer()

                AmountText(amount: total, size: .small)

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(AppColors.secondaryText)
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(.plain)
    }
}

struct AccountRowView: View {
    let account: FinancialAccount

    var body: some View {
        HStack(spacing: 14) {
            InstitutionLogoView(institution: account.institution, size: 40)

            VStack(alignment: .leading, spacing: 3) {
                Text(account.name)
                    .font(AppTypography.headline())
                    .foregroundStyle(AppColors.primaryText)

                HStack(spacing: 6) {
                    Text(account.institution.rawValue)
                    if let masked = account.accountNumberMasked {
                        Text("·")
                        Text(masked)
                    }
                }
                .font(AppTypography.caption())
                .foregroundStyle(AppColors.secondaryText)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                AmountText(amount: account.balance, size: .small)
                CategoryBadge(category: account.category)
            }
        }
        .padding(.vertical, 4)
    }
}

struct InstitutionDetailView: View {
    let institution: InstitutionType
    let accounts: [FinancialAccount]

    private var total: Decimal {
        accounts.reduce(0) { $0 + $1.balance }
    }

    var body: some View {
        List {
            Section {
                HStack {
                    InstitutionLogoView(institution: institution, size: 56)
                    VStack(alignment: .leading, spacing: 4) {
                        Text(institution.rawValue)
                            .font(AppTypography.title())
                        AmountText(amount: total, size: .medium, color: AppColors.accent)
                    }
                    .padding(.vertical, 8)
                }
            }

            Section("Comptes") {
                ForEach(accounts) { account in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(account.name)
                                .font(AppTypography.headline())
                            Spacer()
                            AmountText(amount: account.balance, size: .small)
                        }
                        HStack {
                            CategoryBadge(category: account.category)
                            Spacer()
                            Text(account.lastSyncedAt.formatted(date: .abbreviated, time: .shortened))
                                .font(AppTypography.caption())
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle(institution.rawValue)
        .navigationBarTitleDisplayMode(.inline)
    }
}
