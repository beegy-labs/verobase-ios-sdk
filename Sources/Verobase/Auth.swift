import Foundation

/// Authentication module — mirrors the Flutter and React Native SDKs.
public final class VerobaseAuth {
    private let http: HttpClient
    private let storage: TokenStorage

    init(http: HttpClient, storage: TokenStorage) {
        self.http = http
        self.storage = storage
    }

    // MARK: - Registration & Login

    public func register(_ req: RegisterRequest) async throws {
        let _: [String: AnyCodable] = try await http.post("/v1/auth/register", body: req)
    }

    public func login(_ req: LoginRequest) async throws -> LoginResponse {
        let res: LoginResponse = try await http.post("/v1/auth/login", body: req)
        if let at = res.accessToken, let rt = res.refreshToken {
            storage.setTokens(accessToken: at, refreshToken: rt)
        }
        return res
    }

    public func logout() async throws {
        try await http.post("/v1/auth/logout")
        storage.clearTokens()
    }

    public func refresh() async throws {
        guard let rt = storage.getRefreshToken() else { throw VerobaseError.unauthorized }
        struct Body: Encodable { let refresh_token: String }
        let res: TokenPair = try await http.post("/v1/auth/refresh", body: Body(refresh_token: rt))
        storage.setTokens(accessToken: res.accessToken, refreshToken: res.refreshToken)
    }

    // MARK: - Password

    public func requestPasswordReset(email: String) async throws {
        struct Body: Encodable { let email: String }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/password/reset", body: Body(email: email))
    }

    public func confirmPasswordReset(token: String, newPassword: String) async throws {
        struct Body: Encodable { let token: String; let new_password: String }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/password/confirm", body: Body(token: token, new_password: newPassword))
    }

    // MARK: - Email verification

    public func verifyEmail(token: String) async throws {
        struct Body: Encodable { let token: String }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/email/verify", body: Body(token: token))
    }

    // MARK: - Magic Link

    public func requestMagicLink(email: String) async throws {
        struct Body: Encodable { let email: String }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/magic-link/request", body: Body(email: email))
    }

    public func verifyMagicLink(token: String) async throws -> LoginResponse {
        struct Body: Encodable { let token: String }
        let res: LoginResponse = try await http.post("/v1/auth/magic-link/verify", body: Body(token: token))
        if let at = res.accessToken, let rt = res.refreshToken {
            storage.setTokens(accessToken: at, refreshToken: rt)
        }
        return res
    }

    // MARK: - OTP

    public func requestOtp(email: String) async throws {
        struct Body: Encodable { let email: String }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/otp/request", body: Body(email: email))
    }

    public func verifyOtp(_ req: OtpVerifyRequest) async throws -> LoginResponse {
        let res: LoginResponse = try await http.post("/v1/auth/otp/verify", body: req)
        if let at = res.accessToken, let rt = res.refreshToken {
            storage.setTokens(accessToken: at, refreshToken: rt)
        }
        return res
    }

    // MARK: - MFA

    public func getMfaStatus() async throws -> [String: AnyCodable] {
        try await http.get("/v1/auth/mfa/status")
    }

    public func setupMfa() async throws -> [String: AnyCodable] {
        try await http.post("/v1/auth/mfa/setup", body: EmptyBody())
    }

    public func verifyMfa(code: String) async throws -> [String: AnyCodable] {
        struct Body: Encodable { let code: String }
        return try await http.post("/v1/auth/mfa/verify", body: Body(code: code))
    }

    public func completeMfaLogin(mfaToken: String, code: String) async throws -> LoginResponse {
        struct Body: Encodable { let mfa_token: String; let code: String }
        let res: LoginResponse = try await http.post("/v1/auth/mfa/complete", body: Body(mfa_token: mfaToken, code: code))
        if let at = res.accessToken, let rt = res.refreshToken {
            storage.setTokens(accessToken: at, refreshToken: rt)
        }
        return res
    }

    public func disableMfa(code: String) async throws {
        struct Body: Encodable { let code: String }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/mfa/disable", body: Body(code: code))
    }

    public func regenerateBackupCodes() async throws -> [String] {
        struct Response: Decodable { let codes: [String] }
        let res: Response = try await http.post("/v1/auth/mfa/backup-codes/regenerate", body: EmptyBody())
        return res.codes
    }

    // MARK: - Passkeys

    public func passkeyRegisterStart() async throws -> PasskeyRegisterStartResponse {
        try await http.post("/v1/auth/passkeys/register/start", body: EmptyBody())
    }

    public func passkeyRegisterFinish(challengeId: String, credential: [String: AnyCodable]) async throws {
        struct Body: Encodable { let challenge_id: String; let credential: [String: AnyCodable] }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/passkeys/register/finish", body: Body(challenge_id: challengeId, credential: credential))
    }

    public func passkeyAuthStart() async throws -> PasskeyAuthStartResponse {
        try await http.post("/v1/auth/passkeys/auth/start", body: EmptyBody())
    }

    public func passkeyAuthFinish(challengeId: String, credential: [String: AnyCodable]) async throws -> LoginResponse {
        struct Body: Encodable { let challenge_id: String; let credential: [String: AnyCodable] }
        let res: LoginResponse = try await http.post("/v1/auth/passkeys/auth/finish", body: Body(challenge_id: challengeId, credential: credential))
        if let at = res.accessToken, let rt = res.refreshToken {
            storage.setTokens(accessToken: at, refreshToken: rt)
        }
        return res
    }

    public func listPasskeys() async throws -> [PasskeyCredential] {
        struct Response: Decodable { let passkeys: [PasskeyCredential] }
        let res: Response = try await http.get("/v1/auth/passkeys")
        return res.passkeys
    }

    public func deletePasskey(id: String) async throws {
        try await http.delete("/v1/auth/passkeys/\(id)")
    }

    // MARK: - SSO

    public func listSsoProviders() async throws -> [SsoProvider] {
        struct Response: Decodable { let providers: [SsoProvider] }
        let res: Response = try await http.get("/v1/auth/sso/providers")
        return res.providers
    }

    public func ssoInitiateUrl(provider: String, redirectUri: String) -> URL? {
        // Returns the SSO redirect URL — open in SFSafariViewController or ASWebAuthenticationSession
        var components = URLComponents(string: http.baseUrl + "/v1/auth/sso/\(provider)/initiate")
        components?.queryItems = [
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "service_id", value: http.serviceId),
        ]
        return components?.url
    }

    // MARK: - API Keys

    public func createApiKey(name: String) async throws -> CreatedApiKey {
        struct Body: Encodable { let name: String }
        return try await http.post("/v1/auth/api-keys", body: Body(name: name))
    }

    public func listApiKeys() async throws -> [ApiKey] {
        struct Response: Decodable { let keys: [ApiKey] }
        let res: Response = try await http.get("/v1/auth/api-keys")
        return res.keys
    }

    public func revokeApiKey(id: String) async throws {
        try await http.delete("/v1/auth/api-keys/\(id)")
    }

    // MARK: - Consent / GDPR

    public func getPolicies() async throws -> [Policy] {
        struct Response: Decodable { let policies: [Policy] }
        let res: Response = try await http.get("/v1/auth/policies")
        return res.policies
    }

    public func recordConsent(policyType: String, version: String, agreed: Bool) async throws {
        struct Body: Encodable { let policy_type: String; let version: String; let agreed: Bool }
        let _: [String: AnyCodable] = try await http.post("/v1/auth/consent", body: Body(policy_type: policyType, version: version, agreed: agreed))
    }

    public func getMissingConsents() async throws -> [Policy] {
        struct Response: Decodable { let policies: [Policy] }
        let res: Response = try await http.get("/v1/auth/consent/missing")
        return res.policies
    }

    public func requestDataExport() async throws {
        let _: [String: AnyCodable] = try await http.post("/v1/auth/gdpr/export", body: EmptyBody())
    }

    public func requestAccountDeletion() async throws {
        let _: [String: AnyCodable] = try await http.post("/v1/auth/gdpr/delete", body: EmptyBody())
    }

    // MARK: - Helpers

    public func isAuthenticated() -> Bool {
        storage.getAccessToken() != nil
    }

    public func getAccessToken() -> String? {
        storage.getAccessToken()
    }
}

private struct EmptyBody: Encodable { }
