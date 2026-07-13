import WidgetKit
import SwiftUI

struct PatrimoineEntry: TimelineEntry {
    let date: Date
    let snapshot: WidgetSnapshot?
}

struct PatrimoineProvider: TimelineProvider {
    func placeholder(in context: Context) -> PatrimoineEntry {
        PatrimoineEntry(date: .now, snapshot: Self.demoSnapshot)
    }

    func getSnapshot(in context: Context, completion: @escaping (PatrimoineEntry) -> Void) {
        let snapshot = loadSnapshot() ?? Self.demoSnapshot
        completion(PatrimoineEntry(date: .now, snapshot: snapshot))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<PatrimoineEntry>) -> Void) {
        let snapshot = loadSnapshot() ?? Self.demoSnapshot
        let entry = PatrimoineEntry(date: .now, snapshot: snapshot)
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now) ?? .now
        completion(Timeline(entries: [entry], policy: .after(nextUpdate)))
    }

    private func loadSnapshot() -> WidgetSnapshot? {
        guard let defaults = UserDefaults(suiteName: AppGroupConstants.suiteName),
              let data = defaults.data(forKey: AppGroupConstants.accountsSnapshotKey),
              let snapshot = try? JSONDecoder().decode(WidgetSnapshot.self, from: data) else {
            return nil
        }
        return snapshot
    }

    static let demoSnapshot = WidgetSnapshot(
        totalBalance: 163_428.82,
        currencyCode: "EUR",
        lastUpdated: .now,
        topAccounts: [
            WidgetAccountSummary(id: UUID(), name: "Linxea Spirit 2", institution: "Linxea", balance: 45_680.15, colorHex: "E85D3B"),
            WidgetAccountSummary(id: UUID(), name: "PEA Amundi", institution: "Amundi", balance: 34_210.88, colorHex: "003DA5"),
            WidgetAccountSummary(id: UUID(), name: "Portefeuille actions", institution: "Trade Republic", balance: 18_945.32, colorHex: "1A1A1A")
        ]
    )
}

struct PatrimoineWidgetEntryView: View {
    var entry: PatrimoineProvider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(snapshot: entry.snapshot)
        case .systemMedium:
            MediumWidgetView(snapshot: entry.snapshot)
        case .systemLarge:
            LargeWidgetView(snapshot: entry.snapshot)
        default:
            SmallWidgetView(snapshot: entry.snapshot)
        }
    }
}

struct SmallWidgetView: View {
    let snapshot: WidgetSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .foregroundStyle(Color(hex: "2563EB"))
                Text("Patrimoine")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if let snapshot {
                Text(formatCurrency(snapshot.totalBalance, code: snapshot.currencyCode))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                Text(snapshot.lastUpdated.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } else {
                Text("Ouvrir l'app")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .containerBackground(for: .widget) {
            Color(hex: "F7F8FA")
        }
    }
}

struct MediumWidgetView: View {
    let snapshot: WidgetSnapshot?

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Label("Patrimoine total", systemImage: "chart.pie.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let snapshot {
                    Text(formatCurrency(snapshot.totalBalance, code: snapshot.currencyCode))
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                }

                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let accounts = snapshot?.topAccounts.prefix(2) {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(accounts)) { account in
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color(hex: account.colorHex))
                                .frame(width: 8, height: 8)
                            Text(account.name)
                                .font(.caption2)
                                .lineLimit(1)
                            Spacer()
                            Text(formatCurrency(account.balance, code: snapshot?.currencyCode ?? "EUR"))
                                .font(.caption2)
                                .fontWeight(.medium)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "F7F8FA")
        }
    }
}

struct LargeWidgetView: View {
    let snapshot: WidgetSnapshot?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label("Patrimoine total", systemImage: "chart.pie.fill")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let snapshot {
                Text(formatCurrency(snapshot.totalBalance, code: snapshot.currencyCode))
                    .font(.system(size: 34, weight: .bold, design: .rounded))

                Divider()

                Text("Top comptes")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                ForEach(snapshot.topAccounts) { account in
                    HStack {
                        Circle()
                            .fill(Color(hex: account.colorHex))
                            .frame(width: 10, height: 10)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(account.name)
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text(account.institution)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(formatCurrency(account.balance, code: snapshot.currencyCode))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()

                Text("Mis à jour \(snapshot.lastUpdated.formatted(.relative(presentation: .named)))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(hex: "F7F8FA")
        }
    }
}

private func formatCurrency(_ value: Double, code: String) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .currency
    formatter.currencyCode = code
    formatter.locale = Locale(identifier: "fr_FR")
    formatter.maximumFractionDigits = 0
    return formatter.string(from: NSNumber(value: value)) ?? "\(value) €"
}

struct PatrimoineWidget: Widget {
    let kind: String = "PatrimoineWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PatrimoineProvider()) { entry in
            PatrimoineWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Patrimoine")
        .description("Affichez votre patrimoine total et vos principaux comptes.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

#Preview(as: .systemSmall) {
    PatrimoineWidget()
} timeline: {
    PatrimoineEntry(date: .now, snapshot: PatrimoineProvider.demoSnapshot)
}

#Preview(as: .systemMedium) {
    PatrimoineWidget()
} timeline: {
    PatrimoineEntry(date: .now, snapshot: PatrimoineProvider.demoSnapshot)
}
