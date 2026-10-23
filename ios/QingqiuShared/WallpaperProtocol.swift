import Foundation

enum WallpaperProtocol {
    static let baseURL = URL(string: "https://bizhi.0223323.xyz")!
    static let requestPasteboardName = "com.qingqiu.wallpaper.payload"
    static let resultPasteboardName = "com.qingqiu.wallpaper.result"
    static let requestNotification = "com.qingqiu.wallpaper.set-request"
    static let resultNotification = "com.qingqiu.wallpaper.set-result"
}

struct WallpaperRegistrationResponse: Decodable {
    let deviceId: String
}

struct WallpaperSyncResponse: Decodable {
    let wallpaper: WallpaperAssignment?
}

struct WallpaperAssignment: Decodable {
    let version: String
    let imageURL: URL

    enum CodingKeys: String, CodingKey { case version, imageUrl }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        if let integer = try? values.decode(Int.self, forKey: .version) {
            version = String(integer)
        } else {
            version = try values.decode(String.self, forKey: .version)
        }
        imageURL = try values.decode(URL.self, forKey: .imageUrl)
    }
}

struct WallpaperSetResult: Codable {
    let ok: Bool
    let message: String
    let timestamp: TimeInterval
}
