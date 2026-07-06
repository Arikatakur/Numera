import SwiftUI

/// Category manager (Quanto-style): expense/income tabs, long-press drag to
/// reorder, tap to edit, floating "New category" pill.
struct CategoriesView: View {
    @Environment(DataStore.self) private var store

    enum EditorTarget: Identifiable {
        case new(CategoryKind)
        case edit(UserCategory)

        var id: String {
            switch self {
            case .new(let kind):        return "new-\(kind.rawValue)"
            case .edit(let category):   return category.id.uuidString
            }
        }
    }

    @State private var kind: CategoryKind = .expense
    @State private var editorTarget: EditorTarget?

    private var visible: [UserCategory] { store.categories(of: kind) }

    var body: some View {
        ZStack(alignment: .bottom) {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: AppSpacing.base) {
                kindToggle
                    .padding(.horizontal, AppSpacing.screenMargin)

                List {
                    ForEach(visible) { category in
                        Button {
                            editorTarget = .edit(category)
                        } label: {
                            HStack(spacing: AppSpacing.base) {
                                EmojiIconTile(emoji: category.emoji, colorHex: category.colorHex, size: 44)
                                Text(category.name)
                                    .font(.system(size: 16, weight: .medium, design: .rounded))
                                    .foregroundColor(AppColors.textPrimary)
                                Spacer()
                                Image(systemName: "line.3.horizontal")
                                    .font(.system(size: 14, design: .rounded))
                                    .foregroundColor(AppColors.textTertiary)
                            }
                            .padding(.vertical, 6)
                        }
                        .listRowBackground(AppColors.surfaceCard)
                        .listRowSeparatorTint(AppColors.borderSubtle)
                    }
                    .onMove { source, destination in
                        Haptics.tap()
                        Task { await store.reorderCategories(kind: kind, from: source, to: destination) }
                    }

                    if visible.isEmpty {
                        Text("No \(kind.label.lowercased()) categories yet")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundColor(AppColors.textTertiary)
                            .frame(maxWidth: .infinity)
                            .listRowBackground(Color.clear)
                    }

                    // Keep the last row reachable above the floating pill.
                    Color.clear
                        .frame(height: 70)
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListRowHeight, 56)
            }
            .padding(.top, AppSpacing.sm)

            FloatingPillButton(title: "New category") {
                editorTarget = .new(kind)
            }
            .padding(.bottom, AppSpacing.xl)
        }
        .navigationTitle("Categories")
        .navigationBarTitleDisplayMode(.large)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $editorTarget) { target in
            CategoryEditSheet(target: target)
        }
    }

    private var kindToggle: some View {
        HStack(spacing: 0) {
            ForEach(CategoryKind.allCases) { option in
                Button {
                    Haptics.select()
                    withAnimation(.easeInOut(duration: 0.2)) { kind = option }
                } label: {
                    Text(option.label)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(kind == option ? .black : AppColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 11)
                        .background(kind == option ? AppColors.accent : Color.clear)
                        .cornerRadius(AppRadius.pill)
                }
            }
        }
        .padding(4)
        .background(AppColors.surfaceCard)
        .cornerRadius(AppRadius.pill)
        .overlay(Capsule().stroke(AppColors.borderGlass, lineWidth: 1))
    }
}

// MARK: - Editor sheet

struct CategoryEditSheet: View {
    let target: CategoriesView.EditorTarget

    @Environment(DataStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var name: String
    @State private var emoji: String
    @State private var colorHex: String
    @State private var showDeleteConfirm = false

    private var editing: UserCategory? {
        if case .edit(let category) = target { return category }
        return nil
    }

    private var kind: CategoryKind {
        switch target {
        case .new(let kind):      return kind
        case .edit(let category): return category.kind
        }
    }

    init(target: CategoriesView.EditorTarget) {
        self.target = target
        switch target {
        case .new:
            _name = State(initialValue: "")
            _emoji = State(initialValue: "🧾")
            _colorHex = State(initialValue: UserCategory.palette[0])
        case .edit(let category):
            _name = State(initialValue: category.name)
            _emoji = State(initialValue: category.emoji)
            _colorHex = State(initialValue: category.colorHex)
        }
    }

    private var canSave: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColors.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: AppSpacing.xl) {
                        EmojiIconTile(emoji: emoji, colorHex: colorHex, size: 76)
                            .padding(.top, AppSpacing.sm)

                        nameField
                        colorPalette
                        emojiGrid

                        PrimaryButton(title: editing == nil ? "Create category" : "Save changes") {
                            save()
                        }
                        .opacity(canSave ? 1 : 0.4)
                        .disabled(!canSave)

                        if editing != nil {
                            Button {
                                showDeleteConfirm = true
                            } label: {
                                Text("Delete category")
                                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                                    .foregroundColor(AppColors.danger)
                            }
                            .padding(.bottom, AppSpacing.sm)
                        }
                    }
                    .padding(.horizontal, AppSpacing.screenMargin)
                }
            }
            .navigationTitle(editing == nil ? "New \(kind.label) Category" : "Edit Category")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(AppColors.textSecondary)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.large])
        .confirmationDialog("Delete \(name)?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) {
                if let editing {
                    Haptics.warning()
                    Task { await store.deleteCategory(id: editing.id) }
                }
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Its transactions are kept and will show as Other. Its budget limit is removed.")
        }
    }

    private var nameField: some View {
        TextField("Category name", text: $name)
            .font(.system(size: 16, weight: .medium, design: .rounded))
            .foregroundColor(AppColors.textPrimary)
            .tint(AppColors.accent)
            .padding(AppSpacing.base)
            .background(AppColors.surfaceCard)
            .clipShape(RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: AppRadius.lg, style: .continuous)
                    .stroke(AppColors.borderGlass, lineWidth: 1)
            )
    }

    private var colorPalette: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("COLOR")
                .labelCapsStyle()
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: AppSpacing.md) {
                    ForEach(UserCategory.palette, id: \.self) { hex in
                        Button {
                            Haptics.select()
                            colorHex = hex
                        } label: {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    Circle().stroke(
                                        colorHex == hex ? AppColors.textPrimary : Color.clear,
                                        lineWidth: 2
                                    )
                                    .padding(-4)
                                )
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var emojiGrid: some View {
        VStack(alignment: .leading, spacing: AppSpacing.sm) {
            Text("ICON")
                .labelCapsStyle()
            let columns = Array(repeating: GridItem(.flexible()), count: 8)
            LazyVGrid(columns: columns, spacing: AppSpacing.sm) {
                ForEach(UserCategory.emojiSuggestions, id: \.self) { suggestion in
                    Button {
                        Haptics.select()
                        emoji = suggestion
                    } label: {
                        Text(suggestion)
                            .font(.system(size: 22, design: .rounded))
                            .frame(width: 38, height: 38)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(emoji == suggestion ? AppColors.accent.opacity(0.25) : Color.white.opacity(0.04))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .stroke(emoji == suggestion ? AppColors.accent : Color.clear, lineWidth: 1.5)
                            )
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func save() {
        guard canSave else { return }
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        Haptics.success()
        if var updated = editing {
            updated.name = trimmed
            updated.emoji = emoji
            updated.colorHex = colorHex
            Task { await store.updateCategory(updated) }
        } else {
            let created = UserCategory(
                name: trimmed,
                emoji: emoji,
                colorHex: colorHex,
                kind: kind,
                sortOrder: store.categories(of: kind).count
            )
            Task { await store.addCategory(created) }
        }
        dismiss()
    }
}

#Preview {
    NavigationStack {
        CategoriesView()
    }
    .preferredColorScheme(.dark)
    .environment(DataStore.preview())
    .environment(AppSettings.shared)
}
