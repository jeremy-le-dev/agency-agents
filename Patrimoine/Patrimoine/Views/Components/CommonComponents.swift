import SwiftUI

struct AmountText: View {
    let amount: Decimal
    var currencyCode: String = "EUR"
    var size: AmountSize = .medium
    var color: Color = AppColors.primaryText

    enum AmountSize {
        case large, medium, small

        var font: Font {
            switch self {
            case .large: return AppTypography.largeTitle()
            case .medium: return AppTypography.amount()
            case .small: return AppTypography.smallAmount()
            }
        }
    }

    var body: some View {
        Text(amount.formatted(.currency(code: currencyCode).locale(Locale(identifier: "fr_FR"))))
            .font(size.font)
            .foregroundStyle(color)
            .contentTransition(.numericText())
    }
}

struct CategoryBadge: View {
    let category: AccountCategory

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: category.icon)
                .font(.caption2)
            Text(category.rawValue)
                .font(AppTypography.caption())
        }
        .foregroundStyle(AppColors.secondaryText)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(AppColors.background)
        .clipShape(Capsule())
    }
}

struct InstitutionLogoView: View {
    let institution: InstitutionType
    var size: CGFloat = 44

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.28, style: .continuous)
                .fill(Color.institution(institution))
                .frame(width: size, height: size)

            Text(institution.shortName)
                .font(.system(size: size * 0.32, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
        }
    }
}

struct SyncStatusView: View {
    let lastUpdated: Date
    let isSyncing: Bool

    var body: some View {
        HStack(spacing: 6) {
            if isSyncing {
                ProgressView()
                    .scaleEffect(0.7)
                Text("Synchronisation…")
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.caption)
                Text("Mis à jour \(lastUpdated.formatted(.relative(presentation: .named)))")
            }
        }
        .font(AppTypography.caption())
        .foregroundStyle(AppColors.secondaryText)
    }
}
