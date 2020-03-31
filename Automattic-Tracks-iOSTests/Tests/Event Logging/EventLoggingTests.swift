import XCTest
import OHHTTPStubs
@testable import AutomatticTracks

class EventLoggingTests: XCTestCase {

    private let domain = "event-logging-tests.example"

    func testThatEventsAreUploaded() throws {

        stubResponse(status: "ok")

        try waitForExpectation(timeout: 1.0) { exp in

            let eventLogging = self.eventLogging()
                .withDelegate(MockEventLoggingDelegate()
                    .withUploadFailedCallback { _, _ in
                        XCTFail("The request must succeed")
                    }
                    .withDidFinishUploadingCallback { _ in
                        exp.fulfill()
                    }
            )

            try eventLogging.enqueueLogForUpload(log: LogFile.containingRandomString())
        }
    }

    private func stubResponse(status: String, statusCode: Int32 = 200) {
        stub(condition: isHost(domain)) { _ in
            let stubData = "{status: \"\(status)\"}".data(using: .utf8)!
            return HTTPStubsResponse(data: stubData, statusCode: statusCode, headers: nil)
        }
    }
}

extension EventLoggingTests {
    func eventLogging() -> EventLogging {
        return eventLogging(withUrl: URL(string: "http://\(domain)/test-endpoint")!)
    }

    func eventLogging(withUrl url: URL) -> EventLogging {
        return EventLogging(
            dataSource: MockEventLoggingDataSource()
                .withEncryptionKey()
                .withLogUploadUrl(url),
            delegate: MockEventLoggingDelegate()
        )
    }
}
