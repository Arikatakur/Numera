import Foundation

// Data tools: CSV export/import and full erase (Settings → Data).
//
// CSV format (header row included on export, tolerated on import):
//   date,type,category,account,title,note,amount,currency
//   2026-07-03,expense,Food,Main account,Blue Wave Sushi,,245.00,USD

extension DataStore {
    // MARK: - Export

    /// Writes all transactions to a temp CSV file and returns its URL (for ShareLink).
    func exportCSVFile() -> URL? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        var lines = ["date,type,category,account,title,note,amount,currency"]
        for tx in transactions.sorted(by: { $0.date < $1.date }) {
            let fields = [
                dateFormatter.string(from: tx.date),
                tx.type.rawValue,
                category(tx.categoryId)?.name ?? "",
                account(tx.accountId)?.name ?? tx.accountName,
                tx.title,
                tx.note ?? "",
                "\(tx.amount)",
                settings.currencyCode,
            ]
            lines.append(fields.map(Self.csvEscape).joined(separator: ","))
        }

        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("numera-export-\(dateFormatter.string(from: .now)).csv")
        do {
            try lines.joined(separator: "\n").write(to: url, atomically: true, encoding: .utf8)
            return url
        } catch {
            fail("Couldn't create the export file.", error)
            return nil
        }
    }

    // MARK: - Import

    /// Imports the export format above. Unknown categories/accounts are created
    /// by name. Returns the number of transactions imported (0 on failure).
    func importCSV(from url: URL) async -> Int {
        let secured = url.startAccessingSecurityScopedResource()
        defer { if secured { url.stopAccessingSecurityScopedResource() } }

        guard let text = try? String(contentsOf: url, encoding: .utf8) else {
            errorMessage = "Couldn't read that file."
            return 0
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")

        var imported: [Transaction] = []
        for line in text.split(whereSeparator: \.isNewline) {
            let fields = Self.parseCSVLine(String(line))
            guard fields.count >= 7 else { continue }
            if fields[0].lowercased() == "date" { continue }  // header

            let rawDate = fields[0].trimmingCharacters(in: .whitespaces)
            let date: Date
            if let parsed = dateFormatter.date(from: rawDate) {
                date = parsed
            } else if rawDate.contains("T") {
                date = SupaDate.parse(rawDate)
            } else {
                continue
            }

            guard let type = TransactionType(rawValue: fields[1].lowercased().trimmingCharacters(in: .whitespaces)),
                  let amount = Decimal(string: fields[6], locale: Locale(identifier: "en_US_POSIX")),
                  amount > 0
            else { continue }

            let categoryId = await resolveCategory(named: fields[2], for: type)
            let (accountId, accountName) = await resolveAccount(named: fields[3])
            let note = fields[5].trimmingCharacters(in: .whitespaces)
            var title = fields[4].trimmingCharacters(in: .whitespaces)
            if title.isEmpty { title = category(categoryId)?.name ?? "Imported" }

            imported.append(Transaction(
                type: type,
                amount: amount,
                categoryId: categoryId,
                title: title,
                note: note.isEmpty ? nil : note,
                date: date,
                accountId: accountId,
                accountName: accountName
            ))
        }

        guard !imported.isEmpty else {
            errorMessage = "No importable rows found in that file."
            return 0
        }

        transactions.append(contentsOf: imported)
        sortTransactions()
        guard let uid = await requireUser() else { return imported.count }
        do {
            try await client.from("transactions")
                .insert(imported.map { TransactionDTO($0, userId: uid) })
                .execute()
            return imported.count
        } catch {
            let ids = Set(imported.map(\.id))
            transactions.removeAll { ids.contains($0.id) }
            fail("Import failed — nothing was saved.", error)
            return 0
        }
    }

    private func resolveCategory(named raw: String, for type: TransactionType) async -> UUID? {
        let name = raw.trimmingCharacters(in: .whitespaces)
        guard type != .transfer, !name.isEmpty else { return nil }
        let kind: CategoryKind = type == .income ? .income : .expense
        if let existing = categories.first(where: {
            $0.kind == kind && $0.name.caseInsensitiveCompare(name) == .orderedSame
        }) {
            return existing.id
        }
        let created = UserCategory(
            name: name,
            emoji: "🧾",
            colorHex: UserCategory.palette[categories.count % UserCategory.palette.count],
            kind: kind,
            sortOrder: categories(of: kind).count
        )
        await addCategory(created)
        return created.id
    }

    private func resolveAccount(named raw: String) async -> (UUID?, String) {
        let name = raw.trimmingCharacters(in: .whitespaces)
        guard !name.isEmpty else { return (accounts.first?.id, accounts.first?.name ?? "") }
        if let existing = accounts.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame }) {
            return (existing.id, existing.name)
        }
        let created = Account(name: name, balance: 0, emoji: "💳")
        await addAccount(created)
        return (created.id, created.name)
    }

    // MARK: - Erase

    /// Deletes every row the user owns, then re-seeds default categories and a
    /// main account so the app stays usable.
    func eraseAllData() async {
        guard let uid = await requireUser() else { return }
        do {
            try await client.from("transactions").delete().eq("user_id", value: uid.uuidString).execute()
            try await client.from("budgets").delete().eq("user_id", value: uid.uuidString).execute()
            try await client.from("categories").delete().eq("user_id", value: uid.uuidString).execute()
            try await client.from("accounts").delete().eq("user_id", value: uid.uuidString).execute()

            let seeded = UserCategory.seedDefaults
            let mainAccount = Account(name: "Main account", balance: 0, emoji: "🏦")
            try await client.from("categories")
                .insert(seeded.map { CategoryDTO($0, userId: uid) })
                .execute()
            try await client.from("accounts")
                .insert(AccountDTO(mainAccount, userId: uid))
                .execute()

            transactions = []
            budgets = []
            categories = seeded
            accounts = [mainAccount]
        } catch {
            fail("Erase failed — some data may remain.", error)
            await bootstrap()
        }
    }

    // MARK: - CSV parsing

    /// Minimal RFC-4180-ish line parser (quoted fields, doubled quotes).
    static func parseCSVLine(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false
        let chars = Array(line)
        var i = 0
        while i < chars.count {
            let ch = chars[i]
            if inQuotes {
                if ch == "\"" {
                    if i + 1 < chars.count && chars[i + 1] == "\"" {
                        current.append("\"")
                        i += 2
                        continue
                    }
                    inQuotes = false
                } else {
                    current.append(ch)
                }
            } else if ch == "\"" {
                inQuotes = true
            } else if ch == "," {
                fields.append(current)
                current = ""
            } else {
                current.append(ch)
            }
            i += 1
        }
        fields.append(current)
        return fields
    }

    private static func csvEscape(_ raw: String) -> String {
        let cleaned = raw
            .replacingOccurrences(of: "\r", with: " ")
            .replacingOccurrences(of: "\n", with: " ")
        if cleaned.contains(",") || cleaned.contains("\"") {
            return "\"" + cleaned.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return cleaned
    }
}
