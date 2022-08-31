#if SWIFT_PACKAGE
@testable import AutomatticTracksModel
@testable import AutomatticRemoteLogging
#else
@testable import AutomatticTracks
#endif
import XCTest

class PerformanceTrackingTests: XCTestCase {

    func testConfigurationSampleRateLowerBoundZero() {
        XCTAssertEqual(PerformanceTracking.Configuration(sampleRate: 0.0).sampleRate, 0.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampleRate: -0.1).sampleRate, 0.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampleRate: -1.0).sampleRate, 0.0)
    }

     func testConfigurationSampleRateUpperBoundOne() {
        XCTAssertEqual(PerformanceTracking.Configuration(sampleRate: 1.0).sampleRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampleRate: 1.1).sampleRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampleRate: 2.0).sampleRate, 1.0)
     }
}
