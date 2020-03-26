import XCTest
@testable import AutomatticTracks

class EventLoggingUploadManagerTests: XCTestCase {
    var uploadManager: EventLoggingUploadManager!
    var networkService = MockEventLoggingNetworkService()
    var delegate: MockEventLoggingDelegate!
    var dataSource: MockEventLoggingDataSource!

    override func setUp() {
        delegate = MockEventLoggingDelegate()
        dataSource = MockEventLoggingDataSource()
        networkService = MockEventLoggingNetworkService()

        uploadManager = EventLoggingUploadManager(dataSource: dataSource, delegate: delegate)
        uploadManager.networkService = networkService
    }

    func testThatDelegateIsNotifiedOfNetworkStartAndCompletionForSuccess() {

        async_test(timeout: 1.0) { exp in
            uploadManager.upload(LogFile.containingRandomString(), then:  { _ in exp.fulfill() })
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertTrue(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfNetworkStartForFailure() {

        async_test(timeout: 1.0) { exp in
            networkService.shouldSucceed = false
            uploadManager.upload(LogFile.containingRandomString(), then:  { _ in exp.fulfill() })
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatNetworkStartDoesNotFireWhenDelegateCancelsUpload() {

        async_test(timeout: 1.0) { exp in
            delegate.setShouldUploadLogFiles(false)
            delegate.uploadCancelledByDelegateCallback = { _ in exp.fulfill() }
            uploadManager.upload(LogFile.containingRandomString(), then:  { _ in XCTFail("Callback should not be called") })
        }

        XCTAssertFalse(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertTrue(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfMissingFiles() {
        async_test(timeout: 1.0) { exp in
            delegate.setShouldUploadLogFiles(true)
            delegate.uploadFailedCallback = { error, _ in exp.fulfill() }
            uploadManager.upload(LogFile.withInvalidPath(), then:  { _ in XCTFail("Callback should not be called") })
        }
    }
}
