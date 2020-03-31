import XCTest
@testable import AutomatticTracks

class EventLoggingUploadManagerTests: XCTestCase {

    func testThatDelegateIsNotifiedOfNetworkStartAndCompletionForSuccess() {

        let delegate = MockEventLoggingDelegate()
        let uploadManager = self.uploadManager(delegate: delegate)

        waitForExpectation(timeout: 1.0) { exp in
            uploadManager.upload(LogFile.containingRandomString(), then: { _ in exp.fulfill() })
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertTrue(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfNetworkStartForFailure() {

        let delegate = MockEventLoggingDelegate()

        let uploadManager = self.uploadManager(
            delegate: delegate,
            networkService: MockEventLoggingNetworkService(shouldSucceed: false)
        )

        waitForExpectation(timeout: 1.0) { exp in
            uploadManager.upload(LogFile.containingRandomString(), then: { _ in exp.fulfill() })
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    typealias ExternalExpectationCallback = (XCTestExpectation) -> Void

    func testThatNetworkStartDoesNotFireWhenDelegateCancelsUpload() {

        let delegate = waitForExpectation(timeout: 1.0) { exp -> MockEventLoggingDelegate in

            let delegate = MockEventLoggingDelegate()
                .withShouldUploadLogFilesValue(false)
                .withUploadCancelledCallback { logFile in
                    exp.fulfill()
                }

            self.uploadManager(delegate: delegate).upload(LogFile.containingRandomString(), then: { _ in
                XCTFail("Callback should not be called")
            })

            return delegate
        }

        XCTAssertFalse(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertTrue(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfMissingFiles() {
        waitForExpectation(timeout: 1.0) { exp in
            let delegate = MockEventLoggingDelegate()
                .withUploadFailedCallback { error, _ in
                    exp.fulfill()
                }

            self.uploadManager(delegate: delegate).upload(LogFile.withInvalidPath(), then: {
                _ in XCTFail("Callback should not be called")
            })
        }
    }
}

extension EventLoggingUploadManagerTests {
    func uploadManager(
        delegate: EventLoggingDelegate = MockEventLoggingDelegate(),
        networkService: EventLoggingNetworkService = MockEventLoggingNetworkService(),
        dataSource: EventLoggingDataSource = MockEventLoggingDataSource()
    ) -> EventLoggingUploadManager {
        return EventLoggingUploadManager(dataSource: dataSource, delegate: delegate, networkService: networkService)
    }
}
