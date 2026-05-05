import Foundation

/// Analytics module — fire-and-forget event tracking.
public final class VerobaseAnalytics {
    private let http: HttpClient
    private let storage: TokenStorage

    init(http: HttpClient, storage: TokenStorage) {
        self.http = http
        self.storage = storage
    }

    private var anonymousId: String {
        storage.getOrCreateAnonymousId()
    }

    /// Track a custom event.
    public func track(_ name: String, props: [String: Any]? = nil, revenue: Double? = nil, currency: String? = nil) {
        let payload = TrackEventPayload(
            name: name, props: props, revenue: revenue, currency: currency,
            anonymousId: anonymousId
        )
        Task {
            _ = try? await http.post("/v1/analytics/track", body: payload) as [String: AnyCodable]
        }
    }

    /// Track a screen view.
    public func screenview(name: String, props: [String: Any]? = nil) {
        var merged: [String: Any] = ["screen": name]
        if let props { merged.merge(props) { $1 } }
        track("screenview", props: merged)
    }

    /// Set persistent user properties.
    public func setUserProperties(_ properties: [String: Any]) {
        struct Body: Encodable {
            let properties: [String: AnyCodable]
            let anonymous_id: String
        }
        let body = Body(
            properties: properties.mapValues { AnyCodable($0) },
            anonymous_id: anonymousId
        )
        Task {
            _ = try? await http.post("/v1/analytics/identify", body: body) as [String: AnyCodable]
        }
    }

    /// Capture a Swift `Error` as event `$error`. Fire-and-forget.
    public func trackError(_ error: Error, context: [String: Any]? = nil) {
        let nsError = error as NSError
        var props: [String: Any] = [
            "name": String(describing: type(of: error)),
            "message": nsError.localizedDescription,
            "domain": nsError.domain,
            "code": nsError.code,
        ]
        // Capture call-site stack via Thread (best-effort; release builds may strip symbols).
        props["stack"] = Thread.callStackSymbols.joined(separator: "\n")
        if let context { for (k, v) in context { props[k] = v } }
        track("$error", props: props)
    }

    /// Associate the current user with a group.
    public func group(groupId: String, properties: [String: Any]? = nil) {
        struct Body: Encodable {
            let group_id: String
            let properties: [String: AnyCodable]?
            let anonymous_id: String
        }
        let body = Body(
            group_id: groupId,
            properties: properties?.mapValues { AnyCodable($0) },
            anonymous_id: anonymousId
        )
        Task {
            _ = try? await http.post("/v1/analytics/group", body: body) as [String: AnyCodable]
        }
    }
}
