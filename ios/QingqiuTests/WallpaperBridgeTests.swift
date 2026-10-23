import XCTest
@testable import Qingqiu

final class WallpaperBridgeTests: XCTestCase {
    func testRejectsEmptyImagePayload() {
        XCTAssertThrowsError(try WallpaperBridge().send(imageData: Data()))
    }

    func testSetResultRoundTripsAsJSON() throws {
        let value = WallpaperSetResult(ok: false, message: "unavailable", timestamp: 2)
        let data = try JSONEncoder().encode(value)
        let decoded = try JSONDecoder().decode(WallpaperSetResult.self, from: data)
        XCTAssertEqual(decoded.message, "unavailable")
    }
}
