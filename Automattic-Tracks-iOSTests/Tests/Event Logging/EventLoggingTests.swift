import XCTest
import OHHTTPStubs
@testable import AutomatticTracks

class EventLoggingTests: XCTestCase {

    private let domain = "event-logging-tests.example"
    private let dataSource = MockEventLoggingDataSource().withEncryptionKeys()
    private let delegate = MockEventLoggingDelegate()
    private let queue = MockEventLoggingUploadQueue()
    private let eventLogging = EventLogging()

    override func setUp() {
        dataSource.setLogUploadUrl(URL(string: "http://\(domain)/test-endpoint")!)

        eventLogging.uploadQueue = queue
        eventLogging.dataSource = dataSource
        eventLogging.delegate = delegate
    }

    func testThatEventsAreUploaded() {

        stubResponse(status: "ok")

        queue.add(LogFile.containingRandomString())

        delegate.uploadFailedCallback = { _, _ in XCTFail("The request must succeed") }
        async_test(timeout: 1) { exp in
            delegate.didFinishUploadingCallback = { _ in exp.fulfill() }
            eventLogging.encryptAndUploadLogsIfNeeded()
        }
    }

    func testThatMissingEndpointErrorsAreHandledCorrectly() {

        stubResponse(status: "Endpoint not found", statusCode: 404)

        queue.add(LogFile.containingRandomString())
        delegate.didFinishUploadingCallback = { _ in XCTFail("The request must fail") }

        async_test(timeout: 1) { exp in
            delegate.uploadFailedCallback = { error, _ in
                XCTAssert(error.localizedDescription == "not found")
                exp.fulfill()
            }
            eventLogging.encryptAndUploadLogsIfNeeded()
        }
    }

    func testThatBrokenEndpointErrorsAreHandledCorrectly() {

        stubResponse(status: "Server Error", statusCode: 500)

        queue.add(LogFile.containingRandomString())
        delegate.didFinishUploadingCallback = { _ in XCTFail("The request must fail") }

        async_test(timeout: 1) { exp in
            delegate.uploadFailedCallback = { error, _ in
                XCTAssert(error.localizedDescription == "internal server error")
                exp.fulfill()
            }
            eventLogging.encryptAndUploadLogsIfNeeded()
        }
     }

    func testThatBrokenRequestsAreHandledCorrectly() {
        dataSource.setLogUploadUrl(URL(string: "foo://test")!)

        queue.add(LogFile.containingRandomString())

        async_test(timeout: 1) { exp in
            delegate.uploadFailedCallback = { error, _ in
                XCTAssert(error.localizedDescription == "unsupported URL")
                exp.fulfill()
            }
            eventLogging.encryptAndUploadLogsIfNeeded()
        }
    }

    private func stubResponse(status: String, statusCode: Int32 = 200) {
        stub(condition: isHost(domain)) { _ in
            let stubData = "{status: \"\(status)\"}".data(using: .utf8)!
            return HTTPStubsResponse(data: stubData, statusCode: statusCode, headers: nil)
        }
    }
}
