import XCTest
@testable import AutomatticTracks

class TestExponentialBackoffTimer: XCTestCase {

    func testThatExponentialBackoffTimerIncrementCausesDelayToGrow() {
        var timer = ExponentialBackoffTimer()
        let initialValue = timer.next
        timer.increment()

        XCTAssertGreaterThan(timer.next, initialValue)
    }

    func testThatExponentialBackoffFollowsExpectedCurves() {

        let twosCurve = [2, 4, 8, 16, 32, 64, 128, 256, 512]

        var timer = ExponentialBackoffTimer(minimumDelay: 2)
        for expectedValue in twosCurve {
            timer.increment()
            XCTAssertEqual(timer.delay, expectedValue)
        }

        let sixesCurve = [6, 36, 216, 1296, 7_776, 46_656, 279_936, 1_679_616]

        timer = ExponentialBackoffTimer(minimumDelay: 6, maximumDelay: 2_000_000)
        for expectedValue in sixesCurve {
            timer.increment()
            XCTAssertEqual(timer.delay, expectedValue)
        }
    }

    func testThatExponentialBackoffTimerResetDefaultsToZero() {
        let minimumDelay = 5

        var timer = ExponentialBackoffTimer(minimumDelay: minimumDelay)
        XCTAssertEqual(timer.delay, 0, "Initial delay should be equal to zero")
        XCTAssertLessThan(timer.nextDate.timeIntervalSince(Date()), 0.5)
        // we can't do fine-grained DispatchTime comparison, but if it's less than `.now`, that's
        // the same as "immediately"
        XCTAssertLessThan(timer.next, DispatchTime.now())

        timer.increment()
        XCTAssertEqual(minimumDelay, timer.delay, "Incremented next value should be equal to the initial delay")

        timer.reset()
        XCTAssertEqual(timer.delay, 0, "Next value after reset should be equal to zero")
    }

    @available(iOS 13.0, *)
    func testThatExponentialBackoffTimerDatesMirrorDelay() {
        let minimumDelay = Int.random(in: 2...10)

        var timer = ExponentialBackoffTimer(minimumDelay: minimumDelay)
        XCTAssertEqual(timer.delay, 0, "Initial delay should be equal to zero")
        timer.increment()
        XCTAssertEqual(timer.delay, minimumDelay, "Initial delay should be equal to the minimum delay")

        let expectedDate = Date(timeIntervalSinceNow: TimeInterval(minimumDelay))
        let actualDate = timer.nextDate

        /// The dates should be within 0.5 seconds of each other
        XCTAssertLessThan(expectedDate.timeIntervalSince(actualDate), 0.5)
    }
}
