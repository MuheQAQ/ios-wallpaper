import Foundation

struct WallpaperAPI {
    var session: URLSession = .shared
    var baseURL: URL = WallpaperProtocol.baseURL

    func register(deviceCode: String) async throws -> String {
        var request = URLRequest(url: baseURL.appendingPathComponent("api/devices/register"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["deviceCode": deviceCode])
        let (data, response) = try await session.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(WallpaperRegistrationResponse.self, from: data).deviceId
    }

    func sync(deviceID: String, since: String) async throws -> WallpaperAssignment? {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/sync"), resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "deviceId", value: deviceID), URLQueryItem(name: "since", value: since)]
        let (data, response) = try await session.data(from: components.url!)
        try validate(response)
        return try JSONDecoder().decode(WallpaperSyncResponse.self, from: data).wallpaper
    }

    func download(_ assignment: WallpaperAssignment) async throws -> Data {
        let (data, response) = try await session.data(from: assignment.imageURL)
        try validate(response)
        guard !data.isEmpty, data.count <= 40 * 1024 * 1024 else { throw APIError.invalidImage }
        return data
    }

    private func validate(_ response: URLResponse) throws {
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw APIError.httpFailure((response as? HTTPURLResponse)?.statusCode ?? -1)
        }
    }

    enum APIError: LocalizedError {
        case httpFailure(Int)
        case invalidImage
        var errorDescription: String? {
            switch self {
            case .httpFailure(let code): return "服务器请求失败 (HTTP \(code))"
            case .invalidImage: return "图片为空或超过 40 MB"
            }
        }
    }
}
