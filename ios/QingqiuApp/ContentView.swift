import SwiftUI
import UIKit

struct ContentView: View {
    @StateObject private var model = WallpaperSyncService()
    @State private var resultMessage: String?
    private let bridge = WallpaperBridge()

    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Group {
                    if let data = model.imageData, let image = UIImage(data: data) {
                        Image(uiImage: image).resizable().scaledToFit()
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo").font(.largeTitle)
                            Text("没有已下载壁纸").font(.footnote)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(resultMessage ?? model.status)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                if let version = model.version {
                    LabeledContent("当前版本", value: version)
                        .font(.footnote)
                }

                HStack {
                    Button {
                        Task { await model.sync() }
                    } label: {
                        Label("同步壁纸", systemImage: "arrow.clockwise")
                    }
                    .buttonStyle(.bordered)
                    .disabled(model.busy)

                    Button {
                        sendWallpaper()
                    } label: {
                        Label("设置主屏和锁屏", systemImage: "lock.rotation")
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(model.imageData == nil)
                }
            }
            .padding()
            .navigationTitle("清秋壁纸")
            .task { await model.sync() }
        }
    }

    private func sendWallpaper() {
        guard let data = model.imageData else { return }
        do {
            try bridge.send(imageData: data)
            resultMessage = "已发送给壁纸插件，等待系统确认…"
            Task { @MainActor in
                for _ in 0..<20 {
                    try? await Task.sleep(for: .milliseconds(500))
                    if let result = bridge.readResult() {
                        resultMessage = result.message
                        return
                    }
                }
                resultMessage = "插件无响应，请确认 Dopamine 中 tweak 已启用"
            }
        } catch {
            resultMessage = error.localizedDescription
        }
    }
}
