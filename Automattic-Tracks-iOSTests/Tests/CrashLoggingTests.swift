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
        mockDataProvider.reset()
    }

    func testInitializationWithInvalidDSN() {
        let expectation = XCTestExpectation(description: "Intialization should fail with a DSN error")

        mockDataProvider.sentryDSN = invalidDSN
        mockDataProvider.didLogErrorCallback = { event in
            if event.message == "Project ID path component of DSN is missing" {
                expectation.fulfill()
            }
        }

        CrashLogging.start(withDataProvider: mockDataProvider)

        wait(for: [expectation], timeout: 1)
    }

    func testInitializationWithValidDSNFormat() {
        let expectation = XCTestExpectation(description: "Intialization should pass")
        expectation.isInverted = true

        mockDataProvider.didLogErrorCallback = { event in
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)

        wait(for: [expectation], timeout: 1)
    }

    func testThatUserDataIsBeingStoredForUseInCrashLogs() {
        mockDataProvider.currentUser = testUser
        CrashLogging.start(withDataProvider: mockDataProvider)

        XCTAssert(CrashLogging.sharedInstance.currentUser.email == testUser.email)
        XCTAssert(CrashLogging.sharedInstance.cachedUser?.email == testUser.email)
    }

    func testThatEventsAreNotSentWhenUserOptsOut() {
        mockDataProvider.userHasOptedOut = true

        let expectation = XCTestExpectation(description: "Events should not be sent if user has opted out")

        CrashLogging.sharedInstance.shouldSendEventCallback = { event, shouldSendEvent in
            guard !shouldSendEvent else { return }
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatEventsAreSentWhenUserOptsIn() {
        mockDataProvider.currentUser = testUser

        let expectation = XCTestExpectation(description: "Events be sent if user has opted in")

        CrashLogging.sharedInstance.shouldSendEventCallback = { event, shouldSendEvent in
            guard shouldSendEvent else { return }
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatDataChangeEventsProperlyRefreshData() {

        CrashLogging.start(withDataProvider: mockDataProvider)

        let first_expectation = XCTestExpectation(description: "Current user should be nil")
        first_expectation.isInverted = true

        CrashLogging.sharedInstance.shouldSendEventCallback = { event, shouldSendEvent in
            guard event?.user == nil else { return }
            first_expectation.fulfill()
        }

        mockDataProvider.currentUser = nil
        CrashLogging.logMessage("This is a test")
        wait(for: [first_expectation], timeout: 1)

        /// ============================

        let second_expectation = XCTestExpectation(description: "Current user should still be nil until we update the Crash Logging system")
        second_expectation.isInverted = true

        CrashLogging.sharedInstance.shouldSendEventCallback = { event, shouldSendEvent in
            guard event?.user == nil else { return }
            second_expectation.fulfill()
        }

        mockDataProvider.currentUser = testUser
        CrashLogging.logMessage("This is a test")
        wait(for: [second_expectation], timeout: 1)

        /// ============================

        let third_expectation = XCTestExpectation(description: "Current user should not be nil once we update the Crash Logging system")

        CrashLogging.sharedInstance.shouldSendEventCallback = { event, shouldSendEvent in
            guard event?.user != nil else { return }
            third_expectation.fulfill()
        }

        mockDataProvider.currentUser = testUser
        CrashLogging.setNeedsDataRefresh()
        CrashLogging.logMessage("This is a test")
        wait(for: [third_expectation], timeout: 1)
    }

    #if os(iOS)
    func testWhenRunningOniOSThenEventsAreSentWithApplicationState() throws {
        // Given
        CrashLogging.start(withDataProvider: mockDataProvider)

        let exp = expectation(description: "wait for submittedEvent")

        var submittedEvent: Event?
        CrashLogging.sharedInstance.shouldSendEventCallback = { event, _ in
            submittedEvent = event
            exp.fulfill()
        }

        // When
        CrashLogging.logMessage("This is a test")

        wait(for: [exp], timeout: 1.0)

        // Then
        let event = try XCTUnwrap(submittedEvent)
        XCTAssertNotNil(event.tags?["app.state"])
        XCTAssertEqual(event.tags?["app.state"], "active")
    }
    #endif

    #if os(macOS)
    func testWhenRunningOnMacOSThenEventsDoNotHaveAnApplicationStateTag() throws {
        // Given
        CrashLogging.start(withDataProvider: mockDataProvider)

        let exp = expectation(description: "wait for submittedEvent")

        var submittedEvent: Event?
        CrashLogging.sharedInstance.shouldSendEventCallback = { event, _ in
            submittedEvent = event
            exp.fulfill()
        }

        // When
        CrashLogging.logMessage("This is a test")

        wait(for: [exp], timeout: 1.0)

        // Then
        let tags = try XCTUnwrap(submittedEvent?.tags)
        XCTAssertFalse(tags.keys.contains("app.state"))
    }
    #endif

///
///  These are currently disabled, but are being left here, because I'm hoping to get
///  back to this and sort out how to send stack traces for these events.
///

//    func testThatLoggedErrorsContainAStackTrace() {
//        let expectation = XCTestExpectation(description: "Event should contain a Stack Trace")
//
//        mockDataProvider.didLogErrorCallback = { event in
//            expectation.isInverted = event.stacktrace == nil   // fail if `stacktrace` is nil
//            expectation.fulfill()
//        }
//
//        CrashLogging.start(withDataProvider: mockDataProvider)
//        CrashLogging.logError("This is a test")
//
//        wait(for: [expectation], timeout: 1)
//    }
//
//    func testThatLoggedMessagesContainAStackTrace() {
//        let expectation = XCTestExpectation(description: "Event should contain a Stack Trace")
//
//        mockDataProvider.didLogMessageCallback = { event in
//            debugPrint("=== \(String(describing: event.stacktrace))")
//            expectation.isInverted = event.stacktrace == nil   // fail if `stacktrace` is nil
//            expectation.fulfill()
//        }
//
//        CrashLogging.start(withDataProvider: mockDataProvider)
//        CrashLogging.logMessage("This is a test")
//
//        wait(for: [expectation], timeout: 1)
//    }
}

/// Allow throwing Strings as error
extension String: Error {}

private extension CrashLoggingTests {
    var validDSN: String { return "https://0000000000000000000000000000000@sentry.io/0000000" }
    var invalidDSN: String { return "foo" }
    var testUser: TracksUser { return TracksUser(userID: "foo", email: "bar", username: "baz") }
}

private class MockCrashLoggingDataProvider: CrashLoggingDataProvider {
    var sentryDSN: String = ""
    var userHasOptedOut: Bool = false
    var buildType: String = "test"
    var currentUser: TracksUser? = nil

    func reset() {
        sentryDSN = ""
        userHasOptedOut = false
        buildType = "test"
        currentUser = nil
    }
}
