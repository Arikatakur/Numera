import SwiftUI
import UniformTypeIdentifiers

/// Two-step import: download a ready-to-fill CSV template, fill it in a
/// spreadsheet, then import it back. Replaces the old "pick a file" shortcut so
/// people always start from the correct column structure.
struct ImportTransactionsView: View {
    @Environment(DataStore.self) private var store
    @Environment(AppSettings.self) private var settings

    private struct ShareItem: Identifiable {
        let url: URL
        var id: String { url.absoluteString }
    }

    @State private var showImporter = false
    @State private var shareItem: ShareItem?
    @State private var importMessage: String?

    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: AppSpacing.lg) {
                    Text("Import your data using the template below.")
                        .font(.system(size: 15))
                        .foregroundColor(AppColors.textSecondary)

                    SettingsCard {
                        Button {
                            Haptics.tap()
                            if let url = store.templateCSVFile() {
                                shareItem = ShareItem(url: url)
                            }
                        } label: {
                            SettingsRow(icon: "tablecells", title: "Download template") {
                                SettingsValueChevron()
                            }
                        }
                        SettingsDivider()
                        Button {
                            Haptics.tap()
                            showImporter = true
                        } label: {
                            SettingsRow(icon: "icloud.and.arrow.up", title: "Import data") {
                                SettingsValueChevron()
                            }
                        }
                    }

                    hint

                    Spacer().frame(height: 40)
                }
                .padding(.horizontal, AppSpacing.screenMargin)
                .padding(.top, AppSpacing.sm)
            }
        }
        .navigationTitle("Import transactions")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $shareItem) { item in
            ShareSheet(activityItems: [item.url])
                .presentationDetents([.medium, .large])
        }
        .fileImporter(
            isPresented: $showImporter,
            allowedContentTypes: [.commaSeparatedText, .plainText],
            allowsMultipleSelection: false
        ) { result in
            guard case .success(let urls) = result, let url = urls.first else { return }
            Task {
                let count = await store.importCSV(from: url)
                if count > 0 {
                    Haptics.success()
                    importMessage = "Imported \(count) transaction\(count == 1 ? "" : "s")."
                }
            }
        }
        .alert("Import complete", isPresented: Binding(
            get: { importMessage != nil },
            set: { if !$0 { importMessage = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(importMessage ?? "")
        }
    }

    private var hint: some View {
        (
            Text("Hint: ").font(.system(size: 15, weight: .semibold)).foregroundColor(AppColors.textPrimary)
            + Text("Make sure dates are written as DD/MM/YYYY").foregroundColor(AppColors.textSecondary)
        )
        .font(.system(size: 15))
        .fixedSize(horizontal: false, vertical: true)
    }
}

#Preview {
    NavigationStack {
        ImportTransactionsView()
    }
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
}
