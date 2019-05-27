import XCTest
@testable import AutomatticTracks

class CrashLoggingTests: XCTestCase {

    private let crashLogging = CrashLogging()
    private var mockDataProvider = MockCrashLoggingDataProvider()

    override func setUp() {
        mockDataProvider.sentryDSN = validDSN
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
        mockDataProvider._currentUser = testUser
        CrashLogging.start(withDataProvider: mockDataProvider)

        XCTAssert(CrashLogging.sharedInstance.currentUser.email == testUser.email)
        XCTAssert(CrashLogging.sharedInstance.cachedUser?.email == testUser.email)
    }

    func testThatEventsAreNotSentWhenUserOptsOut() {
        mockDataProvider.userHasOptedOut = true

        let expectation = XCTestExpectation(description: "Events should not be sent if user has opted out")

        CrashLogging.sharedInstance.shouldSendEventCallback = { shouldSendEvent in
            expectation.isInverted = shouldSendEvent   // fail if `shouldSendEvent` is true
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatEventsAreSentWhenUserOptsIn() {
        mockDataProvider._currentUser = testUser

        let expectation = XCTestExpectation(description: "Events be sent if user has opted in")

        CrashLogging.sharedInstance.shouldSendEventCallback = { shouldSendEvent in
            expectation.isInverted = !shouldSendEvent   // succeed if `shouldSendEvent` is true
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatLoggedErrorsContainAStackTrace() {
        let expectation = XCTestExpectation(description: "Event should contain a Stack Trace")

        mockDataProvider.didLogErrorCallback = { event in
            expectation.isInverted = event.stacktrace == nil   // fail if `stacktrace` is nil
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logError("This is a test")

        wait(for: [expectation], timeout: 1)
    }

    func testThatLoggedMessagesContainAStackTrace() {
        let expectation = XCTestExpectation(description: "Event should contain a Stack Trace")

        mockDataProvider.didLogMessageCallback = { event in
            debugPrint("=== \(String(describing: event.stacktrace))")
            expectation.isInverted = event.stacktrace == nil   // fail if `stacktrace` is nil
            expectation.fulfill()
        }

        CrashLogging.start(withDataProvider: mockDataProvider)
        CrashLogging.logMessage("This is a test")

        wait(for: [expectation], timeout: 1)
    }
}

/// Allow throwing Strings as error
extension String: Error {}

extension CrashLoggingTests {
    fileprivate var validDSN: String { return "https://0000000000000000000000000000000@sentry.io/0000000" }
    fileprivate var invalidDSN: String { return "foo" }
    fileprivate var testUser: TracksUser { return TracksUser(userID: "foo", email: "bar", username: "baz") }
}

struct MockCrashLoggingDataProvider : CrashLoggingDataProvider {
    var sentryDSN: String = ""
    var userHasOptedOut: Bool = false
    var buildType: String = "test"

    var _currentUser: TracksUser? = nil

    var currentUser: TracksUser? {
        return _currentUser
    }

    mutating func reset() {
        sentryDSN = ""
        userHasOptedOut = false
        buildType = "test"
        _currentUser = nil
    }
}
