import Foundation

final class DeviceStore {
    private let defaults: UserDefaults
    private let idKey = "qingqiu.deviceId"
    private let versionKey = "qingqiu.wallpaperVersion"

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var deviceID: String? {
        get { defaults.string(forKey: idKey) }
        set { defaults.set(newValue, forKey: idKey) }
    }

    var wallpaperVersion: String {
        get { defaults.string(forKey: versionKey) ?? "0" }
        set { defaults.set(newValue, forKey: versionKey) }
    }
}
