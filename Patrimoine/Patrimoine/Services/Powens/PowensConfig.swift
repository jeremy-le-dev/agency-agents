import Foundation

struct PowensConfig: Sendable {
    let domain: String
    let clientId: String
    let clientSecret: String?
    let redirectURI: String
    let backendTokenURL: String?

    var apiBaseURL: URL {
        URL(string: "https://\(domain).biapi.pro/2.0")!
    }

    var webviewBaseURL: URL {
        URL(string: "https://webview.powens.com")!
    }

    var webviewDomain: String {
        domain.contains("biapi.pro") ? domain : "\(domain).biapi.pro"
    }

    var isConfigured: Bool {
        !domain.isEmpty && !clientId.isEmpty
    }

    var canInitUser: Bool {
        isConfigured && (clientSecret != nil || backendTokenURL != nil)
    }

    func makeConnectURL(temporaryCode: String, connectorCapabilities: String = "bank") -> URL {
        var components = URLComponents(url: webviewBaseURL.appendingPathComponent("fr/connect"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "domain", value: webviewDomain),
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "code", value: temporaryCode),
            URLQueryItem(name: "connector_capabilities", value: connectorCapabilities)
        ]
        return components.url!
    }

    static func load() -> PowensConfig {
        guard let url = Bundle.main.url(forResource: "PowensConfig", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let dict = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: String] else {
            return .placeholder
        }

        return PowensConfig(
            domain: dict["POWENS_DOMAIN"] ?? "",
            clientId: dict["POWENS_CLIENT_ID"] ?? "",
            clientSecret: dict["POWENS_CLIENT_SECRET"],
            redirectURI: dict["POWENS_REDIRECT_URI"] ?? "patrimoine://powens/callback",
            backendTokenURL: dict["POWENS_BACKEND_TOKEN_URL"]
        )
    }

    static let placeholder = PowensConfig(
        domain: "",
        clientId: "",
        clientSecret: nil,
        redirectURI: "patrimoine://powens/callback",
        backendTokenURL: nil
    )
}
