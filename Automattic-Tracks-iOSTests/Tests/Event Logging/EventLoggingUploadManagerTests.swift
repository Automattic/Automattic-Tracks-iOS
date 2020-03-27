import XCTest
@testable import AutomatticTracks

class EventLoggingUploadManagerTests: XCTestCase {

    override func setUp() {
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
    }

    func createUploadManager(networkService: EventLoggingNetworkService = MockEventLoggingNetworkService(),
                             delegate: EventLoggingDelegate = MockEventLoggingDelegate(),
                             dataSource: MockEventLoggingDataSource = MockEventLoggingDataSource.withEncryptionKeys()) -> EventLoggingUploadManager {
        return EventLoggingUploadManager(
            dataSource: dataSource,
            delegate: delegate,
            networkService: networkService
        )
    }

    func testThatDelegateIsNotifiedOfNetworkStartAndCompletionForSuccess() {
        let delegate = MockEventLoggingDelegate()

        waitForExpectation(timeout: 1.0) { exp in
            createUploadManager(delegate: delegate).upload(LogFile.containingRandomString(), then: { _ in exp.fulfill() })
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertTrue(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfNetworkStartForFailure() {
        let delegate = MockEventLoggingDelegate()
        let networkService = MockEventLoggingNetworkService(shouldSucceed: false)

        waitForExpectation(timeout: 1.0) { exp in
            createUploadManager(networkService: networkService, delegate: delegate).upload(LogFile.containingRandomString(), then: { _ in exp.fulfill() })
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatNetworkStartDoesNotFireWhenDelegateCancelsUpload() {
        let delegate = MockEventLoggingDelegate(shouldUploadLogFiles: false)

        waitForExpectation(timeout: 1.0) { exp in
            delegate.uploadCancelledByDelegateCallback = { _ in exp.fulfill() }
            createUploadManager(delegate: delegate).upload(LogFile.containingRandomString(), then: { _ in XCTFail("Callback should not be called") })
        }

        XCTAssertFalse(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertTrue(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfMissingFiles() {
        let delegate = MockEventLoggingDelegate(shouldUploadLogFiles: true)

        waitForExpectation(timeout: 1.0) { exp in
            delegate.uploadFailedCallback = { error, _ in exp.fulfill() }
            createUploadManager(delegate: delegate).upload(LogFile.withInvalidPath(), then: { _ in XCTFail("Callback should not be called") })
        }
    }
}
