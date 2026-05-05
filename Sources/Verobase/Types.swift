import Foundation

// MARK: - Config

public struct VerobaseConfig {
    public let baseUrl: String
    public let serviceId: String

    public init(baseUrl: String, serviceId: String) {
        self.baseUrl = baseUrl
        self.serviceId = serviceId
    }
}

// MARK: - Auth Types

public struct TokenPair: Codable {
    public let accessToken: String
    public let refreshToken: String
    public let expiresIn: Int

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
    }
}

public struct LoginResponse: Codable {
    public let accessToken: String?
    public let refreshToken: String?
    public let expiresIn: Int?
    public let mfaRequired: Bool?
    public let mfaToken: String?

    enum CodingKeys: String, CodingKey {
        case accessToken  = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn    = "expires_in"
        case mfaRequired  = "mfa_required"
        case mfaToken     = "mfa_token"
    }
}

public struct RegisterRequest: Codable {
    public let email: String
    public let password: String
    public let name: String?

    public init(email: String, password: String, name: String? = nil) {
        self.email = email
        self.password = password
        self.name = name
    }
}

public struct LoginRequest: Codable {
    public let email: String
    public let password: String

    public init(email: String, password: String) {
        self.email = email
        self.password = password
    }
}

public struct OtpVerifyRequest: Codable {
    public let email: String
    public let code: String

    public init(email: String, code: String) {
        self.email = email
        self.code = code
    }
}

public struct UserProfile: Codable {
    public let id: String
    public let email: String
    public let name: String?
    public let isEmailVerified: Bool
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case email
        case name
        case isEmailVerified = "is_email_verified"
        case createdAt       = "created_at"
    }
}

// MARK: - Passkey Types

public struct PasskeyRegisterStartResponse: Codable {
    public let challengeId: String
    public let options: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case options
    }
}

public struct PasskeyAuthStartResponse: Codable {
    public let challengeId: String
    public let options: [String: AnyCodable]

    enum CodingKeys: String, CodingKey {
        case challengeId = "challenge_id"
        case options
    }
}

public struct PasskeyCredential: Codable {
    public let id: String
    public let name: String?
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case createdAt = "created_at"
    }
}

// MARK: - SSO Types

public struct SsoProvider: Codable {
    public let provider: String
    public let displayName: String
    public let iconUrl: String?

    enum CodingKeys: String, CodingKey {
        case provider
        case displayName = "display_name"
        case iconUrl     = "icon_url"
    }
}

// MARK: - App Control Types

public enum UpdateType: String, Codable {
    case force     = "FORCE"
    case recommend = "RECOMMEND"
    case none      = "NONE"
}

public struct VersionCheckMessage: Codable {
    public let title: String?
    public let body: String?
    public let actionLabel: String?
    public let actionUrl: String?

    enum CodingKeys: String, CodingKey {
        case title
        case body
        case actionLabel = "action_label"
        case actionUrl   = "action_url"
    }
}

public struct AppVersionCheck: Codable {
    public let updateType: UpdateType
    public let latestVersion: String
    public let message: VersionCheckMessage?

    enum CodingKeys: String, CodingKey {
        case updateType    = "update_type"
        case latestVersion = "latest_version"
        case message
    }
}

public struct MaintenanceStatus: Codable {
    public let isActive: Bool
    public let message: String?
    public let endsAt: String?

    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case message
        case endsAt   = "ends_at"
    }
}

public struct AppNotice: Codable {
    public let id: String
    public let title: String
    public let content: String
    public let type: String?
    public let startsAt: String?
    public let endsAt: String?

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case content
        case type
        case startsAt = "starts_at"
        case endsAt   = "ends_at"
    }
}

// MARK: - Analytics Types

public struct TrackEventPayload: Encodable {
    public let name: String
    public let props: [String: AnyCodable]?
    public let revenue: Double?
    public let currency: String?
    public let platform: String = "ios"
    public let anonymous_id: String

    public init(name: String, props: [String: Any]? = nil, revenue: Double? = nil, currency: String? = nil, anonymousId: String = "") {
        self.name = name
        self.props = props?.mapValues { AnyCodable($0) }
        self.revenue = revenue
        self.currency = currency
        self.anonymous_id = anonymousId
    }
}

// MARK: - AnyCodable helper

public struct AnyCodable: Codable {
    public let value: Any

    public init(_ value: Any) {
        self.value = value
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self)   { value = v; return }
        if let v = try? container.decode(Int.self)    { value = v; return }
        if let v = try? container.decode(Double.self) { value = v; return }
        if let v = try? container.decode(String.self) { value = v; return }
        if let v = try? container.decode([AnyCodable].self) { value = v.map(\.value); return }
        if let v = try? container.decode([String: AnyCodable].self) { value = v.mapValues(\.value); return }
        value = NSNull()
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch value {
        case let v as Bool:             try container.encode(v)
        case let v as Int:              try container.encode(v)
        case let v as Double:           try container.encode(v)
        case let v as String:           try container.encode(v)
        case let v as [Any]:            try container.encode(v.map { AnyCodable($0) })
        case let v as [String: Any]:    try container.encode(v.mapValues { AnyCodable($0) })
        default:                        try container.encodeNil()
        }
    }
}

// MARK: - API Key Types

public struct ApiKey: Codable {
    public let id: String
    public let name: String
    public let prefix: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case prefix
        case createdAt = "created_at"
    }
}

public struct CreatedApiKey: Codable {
    public let id: String
    public let name: String
    public let key: String
    public let createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case key
        case createdAt = "created_at"
    }
}

// MARK: - Consent / GDPR Types

public struct Policy: Codable {
    public let type: String
    public let version: String
    public let content: String
    public let required: Bool
}

public struct ConsentRecord: Codable {
    public let policyType: String
    public let version: String
    public let agreedAt: String

    enum CodingKeys: String, CodingKey {
        case policyType = "policy_type"
        case version
        case agreedAt   = "agreed_at"
    }
}
