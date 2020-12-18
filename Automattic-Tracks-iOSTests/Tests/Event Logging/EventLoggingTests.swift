import XCTest
import OHHTTPStubs
@testable import AutomatticTracks

class EventLoggingTests: XCTestCase {
    private let domain = "event-logging-tests.example"
    lazy var url = URL(string: "http://\(domain)")!

    func testThatOnlyOneFileIsUploadedSimultaneously() {
        stubResponse(domain: domain, status: "ok")

        let uploadCount = Int.random(in: 3...10)
        var isUploading = false

        waitForExpectation() { (exp) in
            exp.expectedFulfillmentCount = uploadCount

            let eventLogging = self.eventLogging(delegate: MockEventLoggingDelegate()
                    .withDidStartUploadingCallback { log in
                        XCTAssertFalse(isUploading, "Only one upload should be running at the same time")
                        isUploading = true
                    }
                    .withDidFinishUploadingCallback { log in
                        XCTAssertTrue(isUploading, "Only one upload should be running at the same time")
                        isUploading = false
                        exp.fulfill()
                    }
            )

            DispatchQueue.concurrentPerform(iterations: uploadCount) { _ in
                try! eventLogging.enqueueLogForUpload(log: LogFile.containingRandomString())
            }
        }
    }

    func testThatAllFilesAreEventuallyUploaded() throws {
        stubResponse(domain: domain, status: "ok")

        let uploadCount = Int.random(in: 3...10)
        let logs = (0...uploadCount).map { _ in LogFile.containingRandomString() }

        try waitForExpectation() { (exp) in
            exp.expectedFulfillmentCount = logs.count

            let delegate = MockEventLoggingDelegate()
                .withDidFinishUploadingCallback { _ in
                    exp.fulfill()
                }

            let eventLogging = self.eventLogging(delegate: delegate)

            /// Adding logs one at at time means the queue will probably drain as fast (if not faster) than we can add them.
            /// This tests the do-the-next-one logic
            try logs.forEach {
                try eventLogging.enqueueLogForUpload(log: $0)
            }
        }
    }

    func testThatDelegateCancellationPausesLogUpload() {
        stubResponse(domain: domain, status: "ok")

        let uploadCount = Int.random(in: 3...10)

        waitForExpectation() { (exp) in
            exp.expectedFulfillmentCount = 1
            exp.assertForOverFulfill = true

            let delegate = MockEventLoggingDelegate()
                .withShouldUploadLogFilesValue(false)
                .withUploadCancelledCallback { _ in
                    exp.fulfill() // we should only ever get one of these, because afterward
                }
                .withDidStartUploadingCallback({ _ in
                    XCTFail("Files should not start uploading")
                })

            let eventLogging = self.eventLogging(delegate: delegate)

            DispatchQueue.concurrentPerform(iterations: uploadCount) { _ in
                try! eventLogging.enqueueLogForUpload(log: LogFile.containingRandomString())
            }
        }
    }

    func testThatRunningOutOfLogFilesDoesNotPauseLogUpload() {
        let delegate = MockEventLoggingDelegate()
        let eventLogging = self.eventLogging(delegate: delegate)
        XCTAssertNil(eventLogging.uploadsPausedUntil)
        eventLogging.uploadNextLogFileIfNeeded()
        Thread.sleep(forTimeInterval: 1.0)
        XCTAssertNil(eventLogging.uploadsPausedUntil)
    }

    func testThatDelegateIsNotifiedOfNetworkStartAndCompletionForSuccess() {
        stubResponse(domain: domain, status: "ok")

        let delegate = MockEventLoggingDelegate()
        let eventLogging = self.eventLogging(delegate: delegate)

        waitForExpectation(timeout: 1.0) { exp in
            eventLogging.upload(log: LogFile.containingRandomString()) { result in
                if case .success = result {
                    exp.fulfill()
                } else {
                    XCTFail()
                }
            }
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertTrue(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfNetworkStartForFailure() {

        let delegate = MockEventLoggingDelegate()
        let eventLogging = self.eventLogging(delegate: delegate)
        eventLogging.networkService = MockEventLoggingNetworkService(shouldSucceed: false)

        waitForExpectation(timeout: 1.0) { exp in
            eventLogging.upload(log: LogFile.containingRandomString()) { _ in exp.fulfill() }
        }

        XCTAssertTrue(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertFalse(delegate.uploadCancelledByDelegateTriggered)
    }

    typealias ExternalExpectationCallback = (XCTestExpectation) -> Void

    func testThatNetworkStartDoesNotFireWhenDelegateCancelsUpload() {

        let delegate = MockEventLoggingDelegate()
            .withShouldUploadLogFilesValue(false)

        let eventLogging = self.eventLogging(delegate: delegate)
        eventLogging.upload(log: LogFile.containingRandomString()) { _ in
            XCTFail("Request should never complete")
        }

        XCTAssertFalse(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertTrue(delegate.uploadCancelledByDelegateTriggered)
    }

    func testThatDelegateIsNotifiedOfMissingFiles() {

        let delegate = MockEventLoggingDelegate()

        let eventLogging = self.eventLogging(delegate: delegate)
        eventLogging.upload(log: LogFile.withInvalidPath()) { _ in
            XCTFail("Request should never complete")
        }

        XCTAssertFalse(delegate.didStartUploadingTriggered)
        XCTAssertFalse(delegate.didFinishUploadingTriggered)
        XCTAssertTrue(delegate.uploadFailedTriggered)
    }

    func testThatRequestContainsCorrectUUID() {
        let log = LogFile.containingRandomString()
        let dataSource = MockEventLoggingDataSource()
        let eventLogging = EventLogging(dataSource: dataSource, delegate: MockEventLoggingDelegate())

        let request = eventLogging.createRequest(for: log)
        XCTAssertEqual(log.uuid, request.allHTTPHeaderFields!["log-uuid"])
    }

    func testThatRequestContainsCorrectAuthenticationToken() {
        let token = String.randomString(length: 64)
        let dataSource = MockEventLoggingDataSource().withAuthenticationToken(token)
        let eventLogging = EventLogging(dataSource: dataSource, delegate: MockEventLoggingDelegate())

        let request = eventLogging.createRequest(for: LogFile.containingRandomString())
        XCTAssertEqual(token, request.allHTTPHeaderFields!["Authorization"])
    }

    func testThatRequestUsesPostMethod() {
        let token = String.randomString(length: 64)
        let dataSource = MockEventLoggingDataSource().withAuthenticationToken(token)
        let eventLogging = EventLogging(dataSource: dataSource, delegate: MockEventLoggingDelegate())

        let request = eventLogging.createRequest(for: LogFile.containingRandomString())
        XCTAssertEqual("POST", request.httpMethod)
    }
}

extension EventLoggingTests {

    func eventLogging(delegate: EventLoggingDelegate) -> EventLogging {
        return EventLogging(dataSource: dataSource(), delegate: delegate)
    }

    func dataSource() -> MockEventLoggingDataSource {
        MockEventLoggingDataSource()
            .withEncryptionKey()
            .withLogUploadUrl(url)
    }
}
