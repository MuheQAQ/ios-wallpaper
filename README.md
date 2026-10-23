# Qingqiu iOS test build

This repository contains a SwiftUI client for iOS 16+ and a rootless SpringBoard tweak intended for Dopamine. The client downloads from the existing Qingqiu server; the tweak is required to attempt setting the Home and Lock screen wallpapers.

## Build artifacts

GitHub Actions builds two artifacts on a macOS runner:

- `Qingqiu-TrollStore.ipa`, an unsigned IPA intended for TrollStore.
- `com.qingqiu.wallpaper.tweak_*.deb`, a rootless package intended for Sileo on Dopamine.

The workflow runs on pushes to `main` and can also be started manually from the Actions tab. Install the IPA with TrollStore and the `.deb` with Sileo. Restart SpringBoard after installing the tweak. To roll back, uninstall both packages from their respective apps.

## Important device validation

This Windows checkout cannot compile Apple targets. A green Actions run proves that the sources compile and package; it does not prove the private wallpaper API calls work on iOS 16.3. The tweak probes `SBWallpaperController` / `SBFWallpaperController` and candidate selectors at runtime, and reports an error when none match. The variant values and selector behavior must be checked on the iPhone 11 before relying on the success result. A system update can change or remove these APIs.

The first run registers a new iOS device with the server using an `ios-<UUID>` device code. The app stores its returned `deviceId` and sync cursor locally. Network behavior depends on the actual server JSON contract; the expected fields are `deviceId`, `wallpaper.version`, and `wallpaper.imageUrl`.

## Build locally on macOS

Install Xcode with iOS 16+ SDK, XcodeGen, and Theos. Then:

```sh
cd ios
xcodegen generate
xcodebuild test -project Qingqiu.xcodeproj -scheme Qingqiu -destination 'platform=iOS Simulator,name=iPhone 16' CODE_SIGNING_ALLOWED=NO
```

Build the tweak from `tweak/QingqiuWallpaper` with `make package THEOS_PACKAGE_SCHEME=rootless` after setting `THEOS`.

## IPC

The app writes image bytes to named pasteboard `com.qingqiu.wallpaper.payload` and posts Darwin notification `com.qingqiu.wallpaper.set-request`. SpringBoard writes a JSON `WallpaperSetResult` to `com.qingqiu.wallpaper.result`, then posts `com.qingqiu.wallpaper.set-result`.

