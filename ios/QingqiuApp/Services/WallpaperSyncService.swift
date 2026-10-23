import Foundation
import Combine
import UIKit

@MainActor
final class WallpaperSyncService: ObservableObject {
    @Published private(set) var imageData: Data?
    @Published private(set) var status = "尚未同步"
    @Published private(set) var busy = false
    @Published private(set) var version: String?

    private let api: WallpaperAPI
    private let store: DeviceStore

    init(api: WallpaperAPI = WallpaperAPI(), store: DeviceStore = DeviceStore()) {
        self.api = api
        self.store = store
        version = store.wallpaperVersion == "0" ? nil : store.wallpaperVersion
    }

    func sync() async {
        guard !busy else { return }
        busy = true
        defer { busy = false }
        do {
            var deviceID = store.deviceID
            if deviceID == nil {
                let code = "ios-\(UUID().uuidString.lowercased())"
                deviceID = try await api.register(deviceCode: code)
                guard let deviceID, !deviceID.isEmpty else { throw SyncError.missingDeviceID }
                store.deviceID = deviceID
            }
            guard let deviceID else { throw SyncError.missingDeviceID }
            guard let assignment = try await api.sync(deviceID: deviceID, since: store.wallpaperVersion) else {
                status = "已是最新壁纸"
                return
            }
            let data = try await api.download(assignment)
            guard UIImage(data: data) != nil else { throw WallpaperAPI.APIError.invalidImage }
            imageData = data
            version = assignment.version
            store.wallpaperVersion = assignment.version
            status = "壁纸 \(assignment.version) 已下载"
        } catch {
            status = error.localizedDescription
        }
    }

    enum SyncError: LocalizedError {
        case missingDeviceID
        var errorDescription: String? { "设备注册响应缺少 deviceId" }
    }
}
