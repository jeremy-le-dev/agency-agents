import Foundation

enum PowensError: LocalizedError {
    case notConfigured
    case invalidResponse
    case apiError(String)
    case noAuthToken
    case userCancelled
    case connectionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Powens n'est pas configuré. Ajoutez PowensConfig.plist."
        case .invalidResponse:
            return "Réponse Powens invalide."
        case .apiError(let message):
            return message
        case .noAuthToken:
            return "Aucun token Powens. Initialisez l'utilisateur d'abord."
        case .userCancelled:
            return "Connexion annulée."
        case .connectionFailed(let message):
            return "Échec de connexion : \(message)"
        }
    }
}

struct PowensAuthInitResponse: Decodable {
    let authToken: String

    enum CodingKeys: String, CodingKey {
        case authToken = "auth_token"
    }
}

private struct PowensAuthInitRequest: Encodable {
    let clientId: String
    let clientSecret: String

    enum CodingKeys: String, CodingKey {
        case clientId = "client_id"
        case clientSecret = "client_secret"
    }
}

struct PowensTemporaryCodeResponse: Decodable {
    let code: String
}

struct PowensAccountsResponse: Decodable {
    let accounts: [PowensAccount]
}

struct PowensAccount: Decodable {
    let id: Int
    let idConnection: Int?
    let name: String?
    let balance: Double?
    let type: String?
    let iban: String?
    let number: String?
    let idConnector: Int?
    let currency: PowensCurrency?

    enum CodingKeys: String, CodingKey {
        case id, name, balance, type, iban, number, currency
        case idConnection = "id_connection"
        case idConnector = "id_connector"
    }
}

struct PowensCurrency: Decodable {
    let id: String?
}

struct PowensConnection: Decodable {
    let id: Int
    let idConnector: Int?
    let connectorName: String?

    enum CodingKeys: String, CodingKey {
        case id
        case idConnector = "id_connector"
        case connectorName = "connector_name"
    }
}

struct PowensConnectionsResponse: Decodable {
    let connections: [PowensConnection]
}

actor PowensAPIClient {
    private let config: PowensConfig
    private let session: URLSession

    init(config: PowensConfig, session: URLSession = .shared) {
        self.config = config
        self.session = session
    }

    func initUser() async throws -> String {
        if let backendURL = config.backendTokenURL, let url = URL(string: backendURL) {
            return try await fetchTokenFromBackend(url: url)
        }

        guard let clientSecret = config.clientSecret, !clientSecret.isEmpty else {
            throw PowensError.notConfigured
        }

        var request = URLRequest(url: config.apiBaseURL.appendingPathComponent("auth/init"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(PowensAuthInitRequest(
            clientId: config.clientId,
            clientSecret: clientSecret
        ))

        let response: PowensAuthInitResponse = try await perform(request)
        return response.authToken
    }

    func temporaryCode(authToken: String) async throws -> String {
        var request = URLRequest(url: config.apiBaseURL.appendingPathComponent("auth/token/code"))
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        let response: PowensTemporaryCodeResponse = try await perform(request)
        return response.code
    }

    func fetchAccounts(authToken: String) async throws -> [PowensAccount] {
        var request = URLRequest(url: config.apiBaseURL.appendingPathComponent("users/me/accounts"))
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        let response: PowensAccountsResponse = try await perform(request)
        return response.accounts
    }

    func fetchConnections(authToken: String) async throws -> [PowensConnection] {
        var request = URLRequest(url: config.apiBaseURL.appendingPathComponent("users/me/connections"))
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        let response: PowensConnectionsResponse = try await perform(request)
        return response.connections
    }

    func buildConnectURL(temporaryCode: String, connectorCapabilities: String = "bank") -> URL {
        var components = URLComponents(url: config.webviewBaseURL.appendingPathComponent("fr/connect"), resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "domain", value: config.domain),
            URLQueryItem(name: "client_id", value: config.clientId),
            URLQueryItem(name: "redirect_uri", value: config.redirectURI),
            URLQueryItem(name: "code", value: temporaryCode),
            URLQueryItem(name: "connector_capabilities", value: connectorCapabilities)
        ]
        return components.url!
    }

    private func fetchTokenFromBackend(url: URL) async throws -> String {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let response: PowensAuthInitResponse = try await perform(request)
        return response.authToken
    }

    private func perform<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw PowensError.invalidResponse
        }

        if http.statusCode >= 400 {
            if let errorBody = try? JSONDecoder().decode([String: String].self, from: data),
               let message = errorBody["description"] ?? errorBody["error_description"] ?? errorBody["message"] {
                throw PowensError.apiError(message)
            }
            throw PowensError.apiError("Erreur HTTP \(http.statusCode)")
        }

        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            throw PowensError.invalidResponse
        }
    }
}
