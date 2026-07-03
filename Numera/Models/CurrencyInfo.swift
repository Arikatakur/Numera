import Foundation

struct CurrencyInfo: Identifiable, Hashable {
    let code: String
    let symbol: String
    let name: String
    let flag: String

    var id: String { code }
}

extension CurrencyInfo {
    static let all: [CurrencyInfo] = [
        CurrencyInfo(code: "USD", symbol: "$",   name: "United States Dollar",     flag: "🇺🇸"),
        CurrencyInfo(code: "EUR", symbol: "€",   name: "Euro",                     flag: "🇪🇺"),
        CurrencyInfo(code: "ILS", symbol: "₪",   name: "Israeli New Shekel",       flag: "🇮🇱"),
        CurrencyInfo(code: "GBP", symbol: "£",   name: "British Pound Sterling",   flag: "🇬🇧"),
        CurrencyInfo(code: "JPY", symbol: "¥",   name: "Japanese Yen",             flag: "🇯🇵"),
        CurrencyInfo(code: "AED", symbol: "AED", name: "United Arab Emirates Dirham", flag: "🇦🇪"),
        CurrencyInfo(code: "SAR", symbol: "SAR", name: "Saudi Riyal",              flag: "🇸🇦"),
        CurrencyInfo(code: "JOD", symbol: "JD",  name: "Jordanian Dinar",          flag: "🇯🇴"),
        CurrencyInfo(code: "EGP", symbol: "E£",  name: "Egyptian Pound",           flag: "🇪🇬"),
        CurrencyInfo(code: "CAD", symbol: "$",   name: "Canadian Dollar",          flag: "🇨🇦"),
        CurrencyInfo(code: "AUD", symbol: "$",   name: "Australian Dollar",        flag: "🇦🇺"),
        CurrencyInfo(code: "NZD", symbol: "$",   name: "New Zealand Dollar",       flag: "🇳🇿"),
        CurrencyInfo(code: "CHF", symbol: "CHF", name: "Swiss Franc",              flag: "🇨🇭"),
        CurrencyInfo(code: "CNY", symbol: "¥",   name: "Chinese Yuan",             flag: "🇨🇳"),
        CurrencyInfo(code: "HKD", symbol: "HK$", name: "Hong Kong Dollar",         flag: "🇭🇰"),
        CurrencyInfo(code: "SGD", symbol: "S$",  name: "Singapore Dollar",         flag: "🇸🇬"),
        CurrencyInfo(code: "KRW", symbol: "₩",   name: "South Korean Won",         flag: "🇰🇷"),
        CurrencyInfo(code: "INR", symbol: "₹",   name: "Indian Rupee",             flag: "🇮🇳"),
        CurrencyInfo(code: "TRY", symbol: "₺",   name: "Turkish Lira",             flag: "🇹🇷"),
        CurrencyInfo(code: "SEK", symbol: "kr",  name: "Swedish Krona",            flag: "🇸🇪"),
        CurrencyInfo(code: "NOK", symbol: "kr",  name: "Norwegian Krone",          flag: "🇳🇴"),
        CurrencyInfo(code: "DKK", symbol: "kr",  name: "Danish Krone",             flag: "🇩🇰"),
        CurrencyInfo(code: "PLN", symbol: "zł",  name: "Polish Złoty",             flag: "🇵🇱"),
        CurrencyInfo(code: "CZK", symbol: "Kč",  name: "Czech Koruna",             flag: "🇨🇿"),
        CurrencyInfo(code: "BRL", symbol: "R$",  name: "Brazilian Real",           flag: "🇧🇷"),
        CurrencyInfo(code: "MXN", symbol: "$",   name: "Mexican Peso",             flag: "🇲🇽"),
        CurrencyInfo(code: "ZAR", symbol: "R",   name: "South African Rand",       flag: "🇿🇦"),
        CurrencyInfo(code: "THB", symbol: "฿",   name: "Thai Baht",                flag: "🇹🇭"),
        CurrencyInfo(code: "PHP", symbol: "₱",   name: "Philippine Peso",          flag: "🇵🇭"),
        CurrencyInfo(code: "UAH", symbol: "₴",   name: "Ukrainian Hryvnia",        flag: "🇺🇦"),
    ]

    static func info(for code: String) -> CurrencyInfo {
        all.first { $0.code == code }
            ?? CurrencyInfo(code: code, symbol: code, name: code, flag: "🏳️")
    }

    static func symbol(for code: String) -> String {
        info(for: code).symbol
    }
}
