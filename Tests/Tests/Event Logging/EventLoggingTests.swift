import XCTest
import OHHTTPStubs

#if SWIFT_PACKAGE
@testable import AutomatticRemoteLogging
@testable import AutomatticEncryptedLogs
#else
@testable import AutomatticTracks
#endif

class EventLoggingTests: XCTestCase {
    private let domain = "event-logging-tests.example"
    lazy var url = URL(string: "http://\(domain)")!

    func testThatOnlyOneFileIsUploadedSimultaneously() {
        // This test is only flaky when running on iOS, not Mac
        #if os(iOS)
            XCTExpectFailure("This test seems to be flaky")
        #endif
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
        // This test is only flaky when running on iOS, not Mac
        #if os(iOS)
            XCTExpectFailure("This test seems to be flaky")
        #endif
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
