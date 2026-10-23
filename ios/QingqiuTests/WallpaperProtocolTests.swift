import XCTest
@testable import Qingqiu

final class WallpaperProtocolTests: XCTestCase {
    func testRegistrationResponseDecodesDeviceID() throws {
        let data = Data(#"{"deviceId":"ios-test-id"}"#.utf8)
        XCTAssertEqual(try JSONDecoder().decode(WallpaperRegistrationResponse.self, from: data).deviceId, "ios-test-id")
    }

    func testNoUpdateResponseDecodesAsNoAssignment() throws {
        let data = Data(#"{"wallpaper":null,"currentVersion":12}"#.utf8)
        XCTAssertNil(try JSONDecoder().decode(WallpaperSyncResponse.self, from: data).wallpaper)
    }

    func testWallpaperAssignmentDecodesVersionAndURL() throws {
        let data = Data(#"{"wallpaper":{"version":13,"imageUrl":"https://example.test/w.jpg"}}"#.utf8)
        let response = try JSONDecoder().decode(WallpaperSyncResponse.self, from: data)
        XCTAssertEqual(response.wallpaper?.version, "13")
        XCTAssertEqual(response.wallpaper?.imageURL.absoluteString, "https://example.test/w.jpg")
    }

    func testSetResultDecodesSuccessAndFailure() throws {
        let success = try JSONDecoder().decode(WallpaperSetResult.self, from: Data(#"{"ok":true,"message":"done","timestamp":1}"#.utf8))
        let failure = try JSONDecoder().decode(WallpaperSetResult.self, from: Data(#"{"ok":false,"message":"API unavailable","timestamp":2}"#.utf8))
        XCTAssertTrue(success.ok)
        XCTAssertFalse(failure.ok)
        XCTAssertEqual(failure.message, "API unavailable")
    }
}
