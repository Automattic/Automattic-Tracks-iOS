#if SWIFT_PACKAGE
@testable import AutomatticTracksModel
@testable import AutomatticRemoteLogging
#else
@testable import AutomatticTracks
#endif
import XCTest

class PerformanceTrackingTests: XCTestCase {

    func testConfigurationSampleRateLowerBoundZero() {
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 0.0 }).sampleRate, 0.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { -0.1 }).sampleRate, 0.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { -1.0 }).sampleRate, 0.0)
    }

     func testConfigurationSampleRateUpperBoundOne() {
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1.0 }).sampleRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1.1 }).sampleRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 2.0 }).sampleRate, 1.0)
     }

    func testConfigurationProfileRateClamping() {
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: 0.4).profilingRate, 0.4)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: -3).profilingRate, 0.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: 0).profilingRate, 0.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: 1).profilingRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: 2).profilingRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: 5_000).profilingRate, 1.0)
        XCTAssertEqual(PerformanceTracking.Configuration(sampler: { 1 }, profilingRate: -0.0).profilingRate, 0.0)
    }
}
