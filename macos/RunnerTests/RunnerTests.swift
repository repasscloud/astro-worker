import XCTest
@testable import astro_worker

class RunnerTests: XCTestCase {
  private let snapshot = """
    {"schema":1,"generatedAt":"2025-01-01T00:00:00.000Z","validUntil":"2025-01-01T01:00:00.000Z",
    "phase":"New Moon","illumination":0.02,"waxing":true,"south":false,"nextPhase":"First Quarter"}
    """

  func testDecodesCurrentTimeline() throws {
    let entries = try XCTUnwrap(MoonWidgetStore.decode(Data("[\(snapshot)]".utf8)))
    XCTAssertEqual(entries.count, 1)
    XCTAssertEqual(entries.last?.phase, "New Moon")
    XCTAssertEqual(entries.last?.validUntil.timeIntervalSince1970, 1_735_693_200)
  }

  func testRejectsCorruptAndOverlappingTimelines() {
    XCTAssertNil(MoonWidgetStore.decode(Data("not a timeline".utf8)))
    XCTAssertNil(MoonWidgetStore.decode(Data("[\(snapshot),\(snapshot)]".utf8)))
    XCTAssertNil(MoonWidgetStore.decode(Data("[\(snapshot.replacingOccurrences(of: "0.02", with: "1.02"))]".utf8)))
  }
}
