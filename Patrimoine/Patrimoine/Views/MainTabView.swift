import SwiftUI

struct DashboardView: View {
    @Environment(AggregationService.self) private var aggregation

    private var groupedByInstitution: [(InstitutionType, [FinancialAccount])] {
        let grouped = Dictionary(grouping: aggregation.snapshot.accounts, by: \.institution)
        return InstitutionType.allCases
            .compactMap { institution -> (InstitutionType, [FinancialAccount])? in
                guard let accounts = grouped[institution], !accounts.isEmpty else { return nil }
                return (institution, accounts)
            }
    }

    private var categoryBreakdown: [(AccountCategory, Decimal)] {
        AccountCategory.allCases.map { ($0, aggregation.balance(for: $0)) }
            .filter { $0.1 > 0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    BalanceHeaderView(
                        totalBalance: aggregation.snapshot.totalBalance,
                        lastUpdated: aggregation.snapshot.lastUpdated,
                        isSyncing: aggregation.isSyncing
                    ) {
                        Task { await aggregation.refreshAll() }
                    }

                    if !categoryBreakdown.isEmpty {
                        CategoryBreakdownView(categories: categoryBreakdown)
                    }

                    NavigationLink {
                        AnalyticsView()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Analyses & graphiques")
                                    .font(AppTypography.headline())
                                    .foregroundStyle(AppColors.primaryText)
                                Text("Épargne, dépenses, cash-flow")
                                    .font(AppTypography.caption())
                                    .foregroundStyle(AppColors.secondaryText)
                            }
                            Spacer()
                            Image(systemName: "chart.xyaxis.line")
                                .font(.title2)
                                .foregroundStyle(AppColors.accent)
                        }
                        .padding(16)
                        .cardStyle()
                    }
                    .buttonStyle(.plain)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Établissements")
                            .font(AppTypography.headline())
                            .foregroundStyle(AppColors.primaryText)
                            .padding(.horizontal, 4)

                        ForEach(groupedByInstitution, id: \.0) { institution, accounts in
                            let total = accounts.reduce(Decimal(0)) { $0 + $1.balance }
                            InstitutionCardView(
                                institution: institution,
                                accounts: accounts,
                                total: total
                            )
                        }
                    }

                    if let error = aggregation.lastError {
                        Text(error)
                            .font(AppTypography.caption())
                            .foregroundStyle(AppColors.negative)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(AppColors.negative.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .background(AppColors.background)
            .navigationTitle("Patrimoine")
            .refreshable {
                await aggregation.refreshAll()
            }
        }
    }
}

struct AccountsListView: View {
    @Environment(AggregationService.self) private var aggregation

    var body: some View {
        NavigationStack {
            List {
                ForEach(AccountCategory.allCases) { category in
                    let accounts = aggregation.accounts(for: category)
                    if !accounts.isEmpty {
                        Section {
                            ForEach(accounts) { account in
                                AccountRowView(account: account)
                            }
                        } header: {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                                Spacer()
                                AmountText(amount: aggregation.balance(for: category), size: .small)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Comptes")
            .refreshable {
                await aggregation.refreshAll()
            }
        }
    }
}

struct ConnectInstitutionView: View {
    @Environment(AggregationService.self) private var aggregation
    @State private var connectingInstitution: InstitutionType?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 8) {
                        Image(systemName: "link.badge.plus")
                            .font(.system(size: 40))
                            .foregroundStyle(AppColors.accent)
                        Text("Connecter un établissement")
                            .font(AppTypography.title())
                        Text(connectionSubtitle)
                            .font(AppTypography.body())
                            .foregroundStyle(AppColors.secondaryText)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)

                    if aggregation.usesPowens {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.shield.fill")
                                .foregroundStyle(AppColors.positive)
                            Text("Connexion sécurisée via Powens (PSD2)")
                                .font(AppTypography.caption())
                                .foregroundStyle(AppColors.secondaryText)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppColors.positive.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }

                    VStack(spacing: 12) {
                        Text("Connectés")
                            .font(AppTypography.headline())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if aggregation.connectedInstitutions.isEmpty {
                            Text("Aucun établissement connecté")
                                .font(AppTypography.caption())
                                .foregroundStyle(AppColors.secondaryText)
                        } else {
                            ForEach(Array(aggregation.connectedInstitutions).sorted(by: { $0.rawValue < $1.rawValue })) { institution in
                                ConnectedInstitutionRow(
                                    institution: institution,
                                    isSyncing: aggregation.isSyncing && connectingInstitution == institution
                                ) {
                                    aggregation.disconnect(institution: institution)
                                }
                            }
                        }
                    }

                    VStack(spacing: 12) {
                        Text("Disponibles")
                            .font(AppTypography.headline())
                            .frame(maxWidth: .infinity, alignment: .leading)

                        ForEach(aggregation.availableInstitutions) { institution in
                            AvailableInstitutionRow(
                                institution: institution,
                                isConnecting: connectingInstitution == institution
                            ) {
                                connectingInstitution = institution
                                Task {
                                    await aggregation.connect(institution: institution)
                                    connectingInstitution = nil
                                }
                            }
                        }

                        if aggregation.availableInstitutions.isEmpty {
                            Text("Tous les établissements sont connectés")
                                .font(AppTypography.caption())
                                .foregroundStyle(AppColors.secondaryText)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Label("Connexion sécurisée PSD2", systemImage: "lock.shield.fill")
                        Label("Données chiffrées de bout en bout", systemImage: "key.fill")
                        Label("Lecture seule — aucun virement", systemImage: "eye.fill")
                    }
                    .font(AppTypography.caption())
                    .foregroundStyle(AppColors.secondaryText)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(AppColors.accent.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(16)
            }
            .background(AppColors.background)
            .navigationTitle("Ajouter")
        }
    }

    private var connectionSubtitle: String {
        if aggregation.usesPowens {
            return "Authentifiez-vous via Powens pour synchroniser vos comptes en lecture seule."
        }
        return "Agrégez vos comptes bancaires, épargne et investissements en un seul endroit."
    }
}

struct ConnectedInstitutionRow: View {
    let institution: InstitutionType
    let isSyncing: Bool
    let onDisconnect: () -> Void

    var body: some View {
        HStack(spacing: 14) {
            InstitutionLogoView(institution: institution)
            Text(institution.rawValue)
                .font(AppTypography.headline())
            Spacer()
            if isSyncing {
                ProgressView()
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppColors.positive)
            }
            Button("Retirer", role: .destructive, action: onDisconnect)
                .font(AppTypography.caption())
        }
        .padding(16)
        .cardStyle()
    }
}

struct AvailableInstitutionRow: View {
    let institution: InstitutionType
    let isConnecting: Bool
    let onConnect: () -> Void

    var body: some View {
        Button(action: onConnect) {
            HStack(spacing: 14) {
                InstitutionLogoView(institution: institution)
                VStack(alignment: .leading, spacing: 2) {
                    Text(institution.rawValue)
                        .font(AppTypography.headline())
                        .foregroundStyle(AppColors.primaryText)
                    Text(institution.defaultCategory.rawValue)
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.secondaryText)
                }
                Spacer()
                if isConnecting {
                    ProgressView()
                } else {
                    Text("Connecter")
                        .font(AppTypography.caption())
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.accent)
                        .clipShape(Capsule())
                }
            }
            .padding(16)
            .cardStyle()
        }
        .buttonStyle(.plain)
        .disabled(isConnecting)
    }
}

struct ProfileView: View {
    @Environment(BiometricLockManager.self) private var biometricLock
    @Environment(AggregationService.self) private var aggregation

    var body: some View {
        NavigationStack {
            List {
                Section("Application") {
                    LabeledContent("Version", value: "1.0.0")
                    LabeledContent("Devise", value: "EUR")
                    LabeledContent("Agrégateur", value: aggregation.usesPowens ? "Powens" : "Démo")
                }

                Section("Widget") {
                    Toggle(isOn: Binding(
                        get: { WidgetDataManager.shared.isBalanceHidden },
                        set: { WidgetDataManager.shared.setBalanceHidden($0) }
                    )) {
                        Label("Masquer les soldes", systemImage: "eye.slash")
                    }
                    Text("S'applique à l'app et au widget d'accueil. Appuyez sur le widget pour ouvrir Patrimoine.")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.secondaryText)
                }

                Section("Sécurité") {
                    if biometricLock.isAvailable {
                        Toggle(isOn: Binding(
                            get: { biometricLock.isEnabled },
                            set: { biometricLock.isEnabled = $0 }
                        )) {
                            Label("Verrouiller avec \(biometricLock.biometricType.label)", systemImage: biometricLock.biometricType.icon)
                        }
                    } else {
                        Label("Biométrie non disponible", systemImage: "exclamationmark.triangle")
                            .foregroundStyle(AppColors.secondaryText)
                    }
                    Label("Token Powens dans le Keychain", systemImage: "key.fill")
                    Label("Données locales chiffrées", systemImage: "lock.fill")
                }

                if aggregation.usesPowens {
                    Section("Powens") {
                        LabeledContent("Statut", value: aggregation.powensService.hasAuthToken ? "Connecté" : "En attente")
                        Button("Réinitialiser la session Powens", role: .destructive) {
                            aggregation.powensService.disconnect()
                        }
                    }
                }

                Section("À propos") {
                    Text("Patrimoine agrège vos comptes Crédit Agricole, Trade Republic, Amundi et Linxea via Powens (PSD2).")
                        .font(AppTypography.caption())
                        .foregroundStyle(AppColors.secondaryText)
                }
            }
            .navigationTitle("Profil")
        }
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Accueil", systemImage: "house.fill")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analyses", systemImage: "chart.xyaxis.line")
                }

            AccountsListView()
                .tabItem {
                    Label("Comptes", systemImage: "list.bullet.rectangle")
                }

            ConnectInstitutionView()
                .tabItem {
                    Label("Ajouter", systemImage: "plus.circle.fill")
                }

            ProfileView()
                .tabItem {
                    Label("Profil", systemImage: "person.fill")
                }
        }
        .tint(AppColors.accent)
        .background(AppColors.background)
    }
}
