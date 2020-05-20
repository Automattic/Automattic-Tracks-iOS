import XCTest
import Sentry
@testable import AutomatticTracks

class CrashLoggingTests: XCTestCase {

    private var mockDataProvider = MockCrashLoggingDataProvider()

    override func setUp() {
        mockDataProvider.sentryDSN = validDSN
        CrashLogging.isStarted = false  // Reset the Crash Logging system
    }

    override func tearDown() {
        CrashLogging.sharedInstance.dataProvider = nil
        mockDataProvider.reset()
    }

    func testThatDoubleInitializationIsPrevented() {

        waitForExpectation(timeout: 1.0) { exp in

            CrashLogging.sharedInstance.crashLoggingStartupCallback = { enabled in
                exp.fulfill()
            }

            CrashLogging.start(withDataProvider: self.mockDataProvider)
            CrashLogging.start(withDataProvider: self.mockDataProvider)
        }
    }

    func testThatUserDataIsBeingStoredForUseInCrashLogs() {
        mockDataProvider.currentUser = testUser
        CrashLogging.start(withDataProvider: mockDataProvider)

        XCTAssert(CrashLogging.sharedInstance.currentUser.email == testUser.email)
    }

    func testThatEventsAreNotSentWhenUserOptsOut() {
        mockDataProvider.userHasOptedOut = true

        let expectation = XCTestExpectation(description: "Events should not be sent if user has opted out")

        CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
            guard !shouldSendEvent else { return }
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatEventsAreSentWhenUserOptsIn() {
        mockDataProvider.currentUser = testUser

        let expectation = XCTestExpectation(description: "Events are sent if user has opted in")

        CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
            guard shouldSendEvent else { return }
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatErrorsAreCorrectlyLogged() {
        mockDataProvider.currentUser = testUser

        CrashLogging.start(withDataProvider: mockDataProvider)

        waitForExpectation(timeout: 1) { exp in

            CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
                exp.fulfill()
            }

            let error = MockError.generic
            CrashLogging.logError(error)
        }
    }

    func testThatDataChangeEventsProperlyRefreshData() {

        CrashLogging.start(withDataProvider: mockDataProvider)

        let first_expectation = XCTestExpectation(description: "Current user should be nil")
        first_expectation.isInverted = true

        CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
            guard event?.user == nil else { return }
            first_expectation.fulfill()
        }

        mockDataProvider.currentUser = nil
        CrashLogging.logMessage("This is a test")
        wait(for: [first_expectation], timeout: 1)

        /// ============================

        let second_expectation = XCTestExpectation(description: "Current user should still be nil until we update the Crash Logging system")
        second_expectation.isInverted = true

        CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
            guard event?.user == nil else { return }
            second_expectation.fulfill()
        }

        mockDataProvider.currentUser = testUser
        CrashLogging.logMessage("This is a test")
        wait(for: [second_expectation], timeout: 1)

        /// ============================

        let third_expectation = XCTestExpectation(description: "Current user should not be nil once we update the Crash Logging system")

        CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
            guard event?.user != nil else { return }
            third_expectation.fulfill()
        }

        mockDataProvider.currentUser = testUser
        CrashLogging.setNeedsDataRefresh()
        CrashLogging.logMessage("This is a test")
        wait(for: [third_expectation], timeout: 1)
    }

    func testThatUninitializedCrashLoggingStackReturnsAnonymousUser() {
        XCTAssertNil(CrashLogging.sharedInstance.dataProvider)

        let user = CrashLogging.sharedInstance.currentUser
        XCTAssertNil(user.email)
        XCTAssertEqual(user.userId, "")
        XCTAssertNil(user.username)
    }

    func testThatUninitializedCrashLoggingStackDoesNotAllowSendingLogs() {
        XCTAssertNil(CrashLogging.sharedInstance.dataProvider)
        XCTAssertTrue(CrashLogging.userHasOptedOut)
    }

    func testThatEnvironmentDataIsCorrectWhenSendingEvents() {
        let environment = UUID().uuidString
        mockDataProvider.buildType = environment

        waitForExpectation(timeout: 1) { exp in
            CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
                XCTAssertEqual(event?.environment, environment)
                exp.fulfill()
            }

            CrashLogging.start(withDataProvider: mockDataProvider)
            CrashLogging.logError(MockError.generic)
        }
    }

    func testThatReleaseDataIsCorrectWhenSendingEvents() {
        let release = UUID().uuidString
        mockDataProvider.releaseName = release

        waitForExpectation(timeout: 1) { exp in
            CrashLogging.sharedInstance.beforeSendCallback = { event, shouldSendEvent in
                XCTAssertEqual(event?.releaseName, release)
                exp.fulfill()
            }

            CrashLogging.start(withDataProvider: mockDataProvider)
            CrashLogging.logError(MockError.generic)
        }
    }

}

/// Allow throwing Strings as error
extension String: Error {}

private extension CrashLoggingTests {
    var validDSN: String { return "https://0000000000000000000000000000000@sentry.io/0000000" }
    var testUser: TracksUser { return TracksUser(userID: "foo", email: "bar", username: "baz") }
}

private class MockCrashLoggingDataProvider: CrashLoggingDataProvider {
    var sentryDSN: String = ""
    var userHasOptedOut: Bool = false
    var buildType: String = "test"
    var currentUser: TracksUser? = nil
    var releaseName: String = ""

    func reset() {
        sentryDSN = ""
        userHasOptedOut = false
        buildType = "test"
        currentUser = nil
        releaseName = ""
    }
}
