import Foundation

/// App Control module — version checks, maintenance, remote config, notices.
public final class VerobaseAppControl {
    private let http: HttpClient

    init(http: HttpClient) {
        self.http = http
    }

    /// Check whether a forced or recommended update is available.
    public func checkVersion(currentVersion: String, platform: String = "ios") async throws -> AppVersionCheck {
        try await http.get(
            "/v1/app-control/version",
            queryItems: [
                URLQueryItem(name: "version", value: currentVersion),
                URLQueryItem(name: "platform", value: platform),
            ]
        )
    }

    /// Check whether the service is in maintenance mode.
    public func checkMaintenance() async throws -> MaintenanceStatus {
        try await http.get("/v1/app-control/maintenance")
    }

    /// Fetch remote config key-value pairs.
    public func getRemoteConfig() async throws -> [String: AnyCodable] {
        struct Response: Decodable { let config: [String: AnyCodable] }
        let res: Response = try await http.get("/v1/app-control/config")
        return res.config
    }

    /// Fetch active notices/banners for the app.
    public func getNotices() async throws -> [AppNotice] {
        struct Response: Decodable { let notices: [AppNotice] }
        let res: Response = try await http.get("/v1/app-control/notices")
        return res.notices
    }
}
