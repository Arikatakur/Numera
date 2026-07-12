import Foundation

/// Central place for outward-facing app metadata: links, handles, and the
/// version string. Update the placeholders below once the App Store listing
/// and social accounts are live.
enum AppInfo {
    /// Instagram handle for "Follow creator on IG" (no leading @).
    static let instagramHandle = "saleemyousef"

    /// App Store numeric ID, e.g. "6749123456". Empty until the app is live —
    /// while empty, "Rate on App Store" falls back to the in-app review prompt.
    static let appStoreID = ""

    // MARK: - Feedback forum (hosted on the ClientVault site)

    static let forumURL = URL(string: "https://clientvault.org/numera/feedback")!

    /// Opens the forum with the composer pre-set to a post type
    /// (`feature` / `bug` / `improvement`).
    static func forumComposeURL(type: String) -> URL {
        URL(string: "https://clientvault.org/numera/feedback?new=\(type)")!
    }

    /// Public, user-facing changelog hosted on the ClientVault site.
    /// Linked from the in-app "What's New" sheet.
    static let changelogURL = URL(string: "https://clientvault.org/numera/changelog")!

    // MARK: - Social

    static var instagramURL: URL {
        URL(string: "https://instagram.com/\(instagramHandle)")!
    }

    /// Deep link that opens the Instagram app directly when installed.
    static var instagramAppURL: URL {
        URL(string: "instagram://user?username=\(instagramHandle)")!
    }

    // MARK: - Version

    static var shortVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0"
    }

    static var build: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// "1.0.0 (1)"
    static var versionString: String {
        "\(shortVersion) (\(build))"
    }
}
