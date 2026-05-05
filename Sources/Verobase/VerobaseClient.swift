import Foundation

/// Main entry point for the Verobase iOS SDK.
///
/// Usage:
/// ```swift
/// let verobase = VerobaseClient(config: VerobaseConfig(
///     baseUrl: "https://api.yourcompany.com",
///     serviceId: "svc_abc123"
/// ))
///
/// try await verobase.auth.login(LoginRequest(email: "user@example.com", password: "secret"))
/// verobase.analytics.track("purchase", props: ["plan": "premium"], revenue: 29.99, currency: "USD")
/// ```
public final class VerobaseClient {
    public let auth: VerobaseAuth
    public let analytics: VerobaseAnalytics
    public let appControl: VerobaseAppControl

    private let storage: TokenStorage
    private let http: HttpClient

    public init(config: VerobaseConfig) {
        let stor = TokenStorage(service: "com.verobase.\(config.serviceId)")
        let client = HttpClient(storage: stor)
        client.configure(baseUrl: config.baseUrl, serviceId: config.serviceId)

        storage = stor
        http = client

        let authModule = VerobaseAuth(http: client, storage: stor)
        auth = authModule
        analytics = VerobaseAnalytics(http: client, storage: stor)
        appControl = VerobaseAppControl(http: client)

        // Wire refresh after all modules are created
        client.setRefresh { [weak authModule] in
            try await authModule?.refresh()
        }
    }
}
