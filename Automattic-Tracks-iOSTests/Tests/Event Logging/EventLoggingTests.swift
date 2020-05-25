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
