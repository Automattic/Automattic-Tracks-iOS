import XCTest
import Sentry

@testable import AutomatticTracks

class CrashLoggingTests: XCTestCase {

    private var mockDataProvider = MockCrashLoggingDataProvider()

    override func setUp() {
        mockDataProvider.sentryDSN = validDSN
    }

    override func tearDown() {
        mockDataProvider.reset()
    }

    func testInitializationWithInvalidDSN() {
        do {
            mockDataProvider.sentryDSN = "--invalid DSN--"
            _ = try CrashLogging(dataProvider: mockDataProvider).start()
            XCTFail("The call above should fail")
        } catch let err {
            XCTAssertEqual("Project ID path component of DSN is missing", err.localizedDescription)
        }
    }

    func testInitializationWithValidDSNFormat() throws {
        _ = try CrashLogging(dataProvider: mockDataProvider).start()
    }

    func testThatUserDataIsBeingPopulatedWhenSendingCrashLogs() throws {
        mockDataProvider.currentUser = testUser
        let crashLogging = try CrashLogging(dataProvider: mockDataProvider).start()
        let event = crashLogging.beforeSend(event: Event(level: .debug))

        XCTAssertEqual(testUser.email, event?.user?.email)
    }

    func testThatEventsAreNotSentWhenUserOptsOut() throws {
        mockDataProvider.userHasOptedOut = true
        let crashLogging = try CrashLogging(dataProvider: mockDataProvider).start()
        let event = crashLogging.beforeSend(event: Event(level: .debug))
        XCTAssertNil(event)
    }

    func testThatEventsAreSentWhenUserOptsIn() throws {
        mockDataProvider.userHasOptedOut = false
        let crashLogging = try CrashLogging(dataProvider: mockDataProvider).start()
        let event = crashLogging.beforeSend(event: Event(level: .debug))
        XCTAssertNotNil(event)
    }

    /// There's no longer any need to call `setNeedsDataRefresh()`, but we'll still test that changes to the `DataProvider` are reflected in subsequent events
    func testThatDataChangeEventsProperlyRefreshData() throws {
        let testUser = TracksUser(email: "test@example.com")
        mockDataProvider.currentUser = testUser
        let crashLogging = try CrashLogging(dataProvider: mockDataProvider).start()

        let firstEvent = crashLogging.beforeSend(event: Event())
        XCTAssertEqual(testUser.sentryUser, firstEvent?.user)

        mockDataProvider.currentUser = nil

        let secondEvent = crashLogging.beforeSend(event: Event())
        XCTAssertNil(secondEvent?.user)
    }

    #if os(iOS)
    func testWhenRunningOniOSThenEventsAreSentWithApplicationState() throws {
        let crashLogging = try CrashLogging(dataProvider: mockDataProvider).start()
        let event = crashLogging.beforeSend(event: Event(level: .debug))
        XCTAssertEqual("active", event?.tags?["app.state"])
    }
    #endif

    #if os(macOS)
    func testWhenRunningOnMacOSThenEventsDoNotHaveAnApplicationStateTag() throws {
        let crashLogging = try CrashLogging(dataProvider: mockDataProvider).start()
        let event = crashLogging.beforeSend(event: Event(level: .debug))
        XCTAssertEqual("unknown", event?.tags?["app.state"])
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
