import SwiftUI

/// "Select your main currency" — searchable list with flags and symbols.
struct CurrencyPickerView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.dismiss) private var dismiss

    @State private var searchText = ""

    private var filtered: [CurrencyInfo] {
        guard !searchText.isEmpty else { return CurrencyInfo.all }
        return CurrencyInfo.all.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
                || $0.code.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.base) {
                searchBar
                    .padding(.horizontal, AppSpacing.screenMargin)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(filtered) { currency in
                            row(currency)
                            Divider().background(AppColors.borderSubtle)
                        }
                    }
                }
            }
            .padding(.top, AppSpacing.sm)
        }
        .navigationTitle("Currency")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    private var searchBar: some View {
        HStack(spacing: AppSpacing.sm) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(AppColors.textTertiary)
                .font(.system(size: 15, design: .rounded))
            TextField("Search currency", text: $searchText)
                .font(.system(size: 15, design: .rounded))
                .foregroundColor(AppColors.textPrimary)
                .tint(AppColors.accent)
                .autocorrectionDisabled()
        }
        .padding(.horizontal, AppSpacing.base)
        .padding(.vertical, 12)
        .background(AppColors.surfaceCard)
        .clipShape(Capsule())
        .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
    }

    private func row(_ currency: CurrencyInfo) -> some View {
        let isSelected = currency.code == settings.currencyCode
        return Button {
            Haptics.success()
            settings.currencyCode = currency.code
            dismiss()
        } label: {
            HStack(spacing: AppSpacing.md) {
                Text(currency.flag)
                    .font(.system(size: 20, design: .rounded))
                Text(currency.symbol)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(AppColors.textSecondary)
                    .frame(width: 46, alignment: .leading)
                Text(currency.name)
                    .font(.system(size: 16, design: .rounded))
                    .foregroundColor(AppColors.textPrimary)
                Spacer()
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, design: .rounded))
                        .foregroundColor(AppColors.accent)
                }
            }
            .padding(.horizontal, AppSpacing.screenMargin)
            .padding(.vertical, 14)
            .background(isSelected ? Color.white.opacity(0.04) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    NavigationStack {
        CurrencyPickerView()
    }
    .preferredColorScheme(.dark)
    .environment(AppSettings.shared)
}
