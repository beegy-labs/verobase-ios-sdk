import Foundation

enum VerobaseError: Error {
    case httpError(statusCode: Int, body: String)
    case decodingError(Error)
    case invalidUrl
    case unauthorized
}

final class HttpClient {
    private let session: URLSession
    private let storage: TokenStorage
    private var onRefresh: () async throws -> Void

    private(set) var baseUrl: String = ""
    private(set) var serviceId: String = ""

    init(storage: TokenStorage) {
        self.session = URLSession.shared
        self.storage = storage
        self.onRefresh = { }
    }

    func setRefresh(_ handler: @escaping () async throws -> Void) {
        self.onRefresh = handler
    }

    func configure(baseUrl: String, serviceId: String) {
        self.baseUrl = baseUrl
        self.serviceId = serviceId
    }

    // MARK: - Public request methods

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        try await request(method: "GET", path: path, queryItems: queryItems, body: nil as String?)
    }

    func post<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "POST", path: path, queryItems: nil, body: body)
    }

    func post(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "POST", path: path, queryItems: nil, body: nil as String?)
    }

    func patch<B: Encodable, T: Decodable>(_ path: String, body: B) async throws -> T {
        try await request(method: "PATCH", path: path, queryItems: nil, body: body)
    }

    func delete(_ path: String) async throws {
        let _: EmptyResponse = try await request(method: "DELETE", path: path, queryItems: nil, body: nil as String?)
    }

    // MARK: - Core

    private func request<B: Encodable, T: Decodable>(
        method: String,
        path: String,
        queryItems: [URLQueryItem]?,
        body: B?,
        retried: Bool = false
    ) async throws -> T {
        var components = URLComponents(string: baseUrl + path)
        if let queryItems { components?.queryItems = queryItems }
        guard let url = components?.url else { throw VerobaseError.invalidUrl }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.setValue(serviceId, forHTTPHeaderField: "X-Service-ID")

        if let token = storage.getAccessToken() {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: req)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0

        if status == 401 && !retried {
            try await onRefresh()
            return try await request(method: method, path: path, queryItems: queryItems, body: body, retried: true)
        }

        guard (200..<300).contains(status) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw VerobaseError.httpError(statusCode: status, body: body)
        }

        if data.isEmpty || data == Data("{}".utf8) {
            if let empty = EmptyResponse() as? T { return empty }
        }

        do {
            let decoder = JSONDecoder()
            return try decoder.decode(T.self, from: data)
        } catch {
            throw VerobaseError.decodingError(error)
        }
    }
}

private struct EmptyResponse: Codable { }
