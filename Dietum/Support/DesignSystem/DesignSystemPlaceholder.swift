import SwiftUI

enum AppSpacing {
    static let small: CGFloat = 8
    static let item: CGFloat = 12
    static let section: CGFloat = 20
    static let screen: CGFloat = 20
    static let insetCard: CGFloat = 20
}

enum AppRadius {
    static let card: CGFloat = 24
    static let insetCard: CGFloat = 20
}

enum AppPalette {
    static let backgroundStart = Color(red: 0.98, green: 0.96, blue: 0.92)
    static let backgroundEnd = Color(red: 0.94, green: 0.97, blue: 0.95)
    static let surface = Color.white.opacity(0.78)
    static let surfaceBorder = Color.black.opacity(0.06)
    static let accent = Color(red: 0.18, green: 0.42, blue: 0.31)
    static let accentSoft = Color(red: 0.85, green: 0.92, blue: 0.88)
    static let textPrimary = Color(red: 0.12, green: 0.14, blue: 0.15)
    static let textSecondary = Color(red: 0.41, green: 0.45, blue: 0.46)
}

enum AppGrid {
    static let columns: [GridItem] = [
        GridItem(.flexible(), spacing: AppSpacing.item, alignment: .top),
        GridItem(.flexible(), spacing: AppSpacing.item, alignment: .top)
    ]
}

struct AppScreenBackground: View {
    var body: some View {
        LinearGradient(
            colors: [AppPalette.backgroundStart, AppPalette.backgroundEnd],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}

extension View {
    func appScreenBackground() -> some View {
        background(AppScreenBackground())
    }
}

struct AppSurfaceCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(AppSpacing.insetCard)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(AppPalette.surface)
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                    .stroke(AppPalette.surfaceBorder, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
            .shadow(color: .black.opacity(0.04), radius: 16, x: 0, y: 8)
    }
}

struct AppHeroCard: View {
    let eyebrow: String
    let title: String
    let message: String

    var body: some View {
        AppSurfaceCard {
            VStack(alignment: .leading, spacing: AppSpacing.item) {
                AppStatusPill(text: eyebrow, systemImage: "leaf.fill")

                Text(title)
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .foregroundStyle(AppPalette.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(message)
                    .font(.callout)
                    .foregroundStyle(AppPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}

struct AppSectionHeader: View {
    let title: String
    let message: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.headline)
                .foregroundStyle(AppPalette.textPrimary)

            Text(message)
                .font(.subheadline)
                .foregroundStyle(AppPalette.textSecondary)
        }
    }
}

struct AppMetricCard: View {
    let title: String
    let value: String
    let detail: String
    let symbolName: String

    var body: some View {
        VStack(alignment: .leading, spacing: AppSpacing.small) {
            Image(systemName: symbolName)
                .font(.headline)
                .foregroundStyle(AppPalette.accent)
                .padding(10)
                .background(AppPalette.accentSoft, in: Circle())

            Text(title)
                .font(.caption.weight(.medium))
                .foregroundStyle(AppPalette.textSecondary)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(AppPalette.textPrimary)

            Text(detail)
                .font(.caption)
                .foregroundStyle(AppPalette.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppSpacing.insetCard)
        .background(AppPalette.surface)
        .overlay(
            RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous)
                .stroke(AppPalette.surfaceBorder, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: AppRadius.card, style: .continuous))
    }
}

struct AppChecklistItem: View {
    let text: String

    var body: some View {
        Label {
            Text(text)
        } icon: {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppPalette.accent)
        }
        .font(.subheadline)
        .foregroundStyle(AppPalette.textPrimary)
    }
}

struct AppStatusPill: View {
    let text: String
    let systemImage: String

    var body: some View {
        Label(text, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .foregroundStyle(AppPalette.accent)
            .padding(.horizontal, AppSpacing.item)
            .padding(.vertical, AppSpacing.small)
            .background(AppPalette.accentSoft, in: Capsule())
    }
}

struct AppToolbarButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(AppPalette.accent)
            .padding(.horizontal, AppSpacing.item)
            .padding(.vertical, 9)
            .background(
                Capsule()
                    .fill(AppPalette.accentSoft.opacity(configuration.isPressed ? 0.7 : 1))
            )
    }
}

struct AppProminentButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.horizontal, AppSpacing.section)
            .padding(.vertical, 14)
            .frame(maxWidth: .infinity)
            .background(
                Capsule()
                    .fill(AppPalette.accent.opacity(configuration.isPressed ? 0.85 : 1))
            )
    }
}

extension ButtonStyle where Self == AppProminentButtonStyle {
    static var appProminent: AppProminentButtonStyle {
        AppProminentButtonStyle()
    }
}
