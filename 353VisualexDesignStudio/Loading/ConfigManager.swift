import Foundation
import AppsFlyerLib

struct ConfigResponse {
    let ok: Bool
    let url: String?
    let expires: Int64?
    let message: String?
}

enum ConfigManagerKeys {
    static let savedRecord = "ConfigManagerStoredConfig"
    static let savedURL = "ConfigManagerSavedURL"
    static let savedExpires = "ConfigManagerSavedExpires"
}

enum ConfigManagerOptionalData {
    static var pushToken: String?
    static var firebaseProjectId: String?
}

struct ConfigDebugSnapshot {
    let endpoint: String
    let requestBodyJSON: String
    let httpStatus: Int?
    let responseBodyJSON: String?
    let parsedOk: Bool?
    let parsedURL: String?
    let parsedExpires: Int64?
    let parsedMessage: String?
    let errorDescription: String?
}

final class ConfigManager {

    static let shared = ConfigManager()

    var configEndpointURL: URL? = URL(string: "https://visualexdesignstudio.com/config.php")

    var storeId: String = "id6809893592"

    private(set) var lastDebugSnapshot: ConfigDebugSnapshot?

    private init() {
        migrateLegacyKeysIfNeeded()
    }

    var savedURL: URL? {
        storedConfig?.url
    }

    var savedExpires: Int64? {
        storedConfig?.expires
    }

    var isSavedURLValid: Bool {
        guard let record = storedConfig else { return false }
        guard record.expires > Int64(Date().timeIntervalSince1970) else {
            clearStoredConfig()
            return false
        }
        return true
    }

    private var storedConfig: StoredConfig? {
        guard let data = UserDefaults.standard.data(forKey: ConfigManagerKeys.savedRecord) else {
            return nil
        }
        guard let record = try? JSONDecoder().decode(StoredConfig.self, from: data) else {
            clearStoredConfig()
            return nil
        }
        return record
    }

    func buildRequestBody() -> Data? {
        let body = buildRequestBodyDictionary()
        return try? JSONSerialization.data(withJSONObject: body)
    }

    func requestConfig(completion: @escaping (Result<ConfigResponse, Error>) -> Void) {
        guard let endpoint = configEndpointURL else {
            lastDebugSnapshot = ConfigDebugSnapshot(
                endpoint: "nil",
                requestBodyJSON: prettyJSONString(from: buildRequestBodyDictionary()) ?? "{}",
                httpStatus: nil,
                responseBodyJSON: nil,
                parsedOk: nil,
                parsedURL: nil,
                parsedExpires: nil,
                parsedMessage: nil,
                errorDescription: ConfigError.missingEndpoint.localizedDescription
            )
            completion(.failure(ConfigError.missingEndpoint))
            return
        }
        guard let body = buildRequestBody() else {
            lastDebugSnapshot = ConfigDebugSnapshot(
                endpoint: endpoint.absoluteString,
                requestBodyJSON: "{}",
                httpStatus: nil,
                responseBodyJSON: nil,
                parsedOk: nil,
                parsedURL: nil,
                parsedExpires: nil,
                parsedMessage: nil,
                errorDescription: ConfigError.failedToBuildBody.localizedDescription
            )
            completion(.failure(ConfigError.failedToBuildBody))
            return
        }

        let requestBodyJSON = prettyJSONString(from: body) ?? String(data: body, encoding: .utf8) ?? "{}"

        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = body
        request.timeoutInterval = 10

        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self else { return }
            let http = response as? HTTPURLResponse
            let statusCode = http?.statusCode
            let rawResponse = Self.prettyJSONString(from: data)
                ?? data.flatMap { String(data: $0, encoding: .utf8) }

            if let error = error {
                self.lastDebugSnapshot = ConfigDebugSnapshot(
                    endpoint: endpoint.absoluteString,
                    requestBodyJSON: requestBodyJSON,
                    httpStatus: statusCode,
                    responseBodyJSON: rawResponse,
                    parsedOk: nil,
                    parsedURL: nil,
                    parsedExpires: nil,
                    parsedMessage: nil,
                    errorDescription: error.localizedDescription
                )
                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            let code = statusCode ?? 0
            let parsed = self.parseConfigResponse(data: data, statusCode: code)
            switch parsed {
            case .success(let config):
                self.lastDebugSnapshot = ConfigDebugSnapshot(
                    endpoint: endpoint.absoluteString,
                    requestBodyJSON: requestBodyJSON,
                    httpStatus: code,
                    responseBodyJSON: rawResponse,
                    parsedOk: config.ok,
                    parsedURL: config.url,
                    parsedExpires: config.expires,
                    parsedMessage: config.message,
                    errorDescription: nil
                )
                if config.ok,
                   let url = config.url,
                   let expires = config.expires,
                   URL(string: url) != nil {
                    self.saveStoredConfig(urlString: url, expires: expires)
                }
                DispatchQueue.main.async { completion(.success(config)) }
            case .failure(let parseError):
                self.lastDebugSnapshot = ConfigDebugSnapshot(
                    endpoint: endpoint.absoluteString,
                    requestBodyJSON: requestBodyJSON,
                    httpStatus: code,
                    responseBodyJSON: rawResponse,
                    parsedOk: nil,
                    parsedURL: nil,
                    parsedExpires: nil,
                    parsedMessage: nil,
                    errorDescription: parseError.localizedDescription
                )
                DispatchQueue.main.async { completion(.failure(parseError)) }
            }
        }
        task.resume()
    }

    func buildRequestBodyDictionary() -> [String: Any] {
        var body: [String: Any] = [:]

        if let conversionString = AppsFlyerManager.shared.conversionDataString,
           let data = conversionString.data(using: .utf8),
           let conversion = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for (key, value) in conversion {
                body[key] = value
            }
        }

        if body["af_id"] == nil {
            body["af_id"] = AppsFlyerLib.shared().getAppsFlyerUID()
        }
        if body["bundle_id"] == nil {
            body["bundle_id"] = Bundle.main.bundleIdentifier ?? ""
        }
        if body["os"] == nil {
            body["os"] = "iOS"
        }
        if body["store_id"] == nil {
            body["store_id"] = storeId
        }
        if body["locale"] == nil {
            body["locale"] = Locale.current.identifier
        }
        if let token = ConfigManagerOptionalData.pushToken, body["push_token"] == nil {
            body["push_token"] = token
        }
        if let projectId = ConfigManagerOptionalData.firebaseProjectId, body["firebase_project_id"] == nil {
            body["firebase_project_id"] = projectId
        }

        return body
    }

    static func prettyJSONString(from data: Data?) -> String? {
        guard let data, !data.isEmpty else { return nil }
        guard let object = try? JSONSerialization.jsonObject(with: data),
              let pretty = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: pretty, encoding: .utf8) else {
            return String(data: data, encoding: .utf8)
        }
        return string
    }

    static func prettyJSONString(from dictionary: [String: Any]) -> String? {
        guard JSONSerialization.isValidJSONObject(dictionary),
              let data = try? JSONSerialization.data(withJSONObject: dictionary, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }
        return string
    }

    private func prettyJSONString(from data: Data) -> String? {
        Self.prettyJSONString(from: data)
    }

    private func prettyJSONString(from dictionary: [String: Any]) -> String? {
        Self.prettyJSONString(from: dictionary)
    }

    private func parseConfigResponse(data: Data?, statusCode: Int) -> Result<ConfigResponse, Error> {
        guard statusCode == 200 else {
            return .failure(ConfigError.invalidResponse)
        }
        guard let data else {
            return .failure(ConfigError.invalidResponse)
        }
        let decoder = JSONDecoder()
        guard let payload = try? decoder.decode(ConfigPayload.self, from: data) else {
            return .failure(ConfigError.invalidResponse)
        }
        let expires = payload.expires?.int64Value
        let url = payload.url?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasValidURL = url.flatMap { URL(string: $0) } != nil
        let isFresh = expires.map { $0 > Int64(Date().timeIntervalSince1970) } ?? false
        let ok = payload.ok && hasValidURL && isFresh
        return .success(
            ConfigResponse(
                ok: ok,
                url: url,
                expires: expires,
                message: payload.message
            )
        )
    }

    private func saveStoredConfig(urlString: String, expires: Int64) {
        guard let url = URL(string: urlString) else { return }
        let record = StoredConfig(url: url, expires: expires)
        guard let data = try? JSONEncoder().encode(record) else { return }
        UserDefaults.standard.set(data, forKey: ConfigManagerKeys.savedRecord)
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedURL)
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedExpires)
    }

    private func clearStoredConfig() {
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedRecord)
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedURL)
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedExpires)
    }

    private func migrateLegacyKeysIfNeeded() {
        if storedConfig != nil {
            UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedURL)
            UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedExpires)
            return
        }
        let rawURL = UserDefaults.standard.string(forKey: ConfigManagerKeys.savedURL)
        let expires = UserDefaults.standard.object(forKey: ConfigManagerKeys.savedExpires) as? Int64
            ?? (UserDefaults.standard.object(forKey: ConfigManagerKeys.savedExpires) as? Int).map { Int64($0) }
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedURL)
        UserDefaults.standard.removeObject(forKey: ConfigManagerKeys.savedExpires)
        guard let rawURL, let url = URL(string: rawURL), let expires, expires > Int64(Date().timeIntervalSince1970) else { return }
        saveStoredConfig(urlString: url.absoluteString, expires: expires)
    }
}

private struct StoredConfig: Codable {
    let url: URL
    let expires: Int64
}

private struct ConfigPayload: Decodable {
    let ok: Bool
    let url: String?
    let expires: FlexibleExpires?
    let message: String?
}

private enum FlexibleExpires: Decodable {
    case int(Int64)
    case string(String)

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(Int64.self) {
            self = .int(value)
            return
        }
        if let value = try? container.decode(Int.self) {
            self = .int(Int64(value))
            return
        }
        if let value = try? container.decode(String.self) {
            self = .string(value)
            return
        }
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "expires")
    }

    var int64Value: Int64? {
        switch self {
        case .int(let value):
            return value
        case .string(let raw):
            return Int64(raw.trimmingCharacters(in: .whitespacesAndNewlines))
        }
    }
}

enum ConfigError: LocalizedError {
    case missingEndpoint
    case failedToBuildBody
    case invalidResponse
    var errorDescription: String? {
        switch self {
        case .missingEndpoint: return "Config endpoint URL not set"
        case .failedToBuildBody: return "Failed to build request body"
        case .invalidResponse: return "Invalid config response"
        }
    }
}
