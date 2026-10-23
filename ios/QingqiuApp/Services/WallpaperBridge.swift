import Darwin
import UIKit

struct WallpaperBridge {
    func send(imageData: Data) throws {
        guard UIImage(data: imageData) != nil else { throw BridgeError.invalidImage }
        let pasteboard = UIPasteboard(name: UIPasteboard.Name(WallpaperProtocol.requestPasteboardName), create: true)
        pasteboard?.setData(imageData, forPasteboardType: "public.data")
        guard pasteboard?.data(forPasteboardType: "public.data") != nil else { throw BridgeError.pasteboardUnavailable }
        let status = notify_post(WallpaperProtocol.requestNotification)
        guard status == NOTIFY_STATUS_OK else { throw BridgeError.notificationFailed(status) }
    }

    func readResult() -> WallpaperSetResult? {
        let pasteboard = UIPasteboard(name: UIPasteboard.Name(WallpaperProtocol.resultPasteboardName), create: false)
        guard let data = pasteboard?.data(forPasteboardType: "public.json") else { return nil }
        return try? JSONDecoder().decode(WallpaperSetResult.self, from: data)
    }

    enum BridgeError: LocalizedError {
        case invalidImage, pasteboardUnavailable, notificationFailed(Int32)
        var errorDescription: String? {
            switch self {
            case .invalidImage: return "下载内容不是可解码图片"
            case .pasteboardUnavailable: return "无法向壁纸插件传递图片"
            case .notificationFailed(let code): return "壁纸插件通知失败 (\(code))"
            }
        }
    }
}
