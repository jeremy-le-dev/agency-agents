import Foundation

enum AppGroupConstants {
    static let suiteName = "group.com.patrimoine.app"
    static let totalBalanceKey = "totalBalance"
    static let lastUpdatedKey = "lastUpdated"
    static let accountsSnapshotKey = "accountsSnapshot"
    static let currencyCodeKey = "currencyCode"
    static let balanceHiddenKey = "balanceHidden"
    static let widgetKind = "PatrimoineWidget"
    static let appDeepLink = "patrimoine://home"
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
    let isBalanceHidden: Bool

    init(
        totalBalance: Double,
        currencyCode: String,
        lastUpdated: Date,
        topAccounts: [WidgetAccountSummary],
        isBalanceHidden: Bool = false
    ) {
        self.totalBalance = totalBalance
        self.currencyCode = currencyCode
        self.lastUpdated = lastUpdated
        self.topAccounts = topAccounts
        self.isBalanceHidden = isBalanceHidden
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        totalBalance = try container.decode(Double.self, forKey: .totalBalance)
        currencyCode = try container.decode(String.self, forKey: .currencyCode)
        lastUpdated = try container.decode(Date.self, forKey: .lastUpdated)
        topAccounts = try container.decode([WidgetAccountSummary].self, forKey: .topAccounts)
        isBalanceHidden = try container.decodeIfPresent(Bool.self, forKey: .isBalanceHidden) ?? false
    }
}

import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: UInt64
        switch hex.count {
        case 6:
            (r, g, b) = ((int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255
        )
    }
}
