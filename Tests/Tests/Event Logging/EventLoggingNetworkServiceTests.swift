import XCTest
import OHHTTPStubs

#if SWIFT_PACKAGE
@testable import AutomatticRemoteLogging
@testable import AutomatticEncryptedLogs
#else
@testable import AutomatticTracks
#endif

class EventLoggingNetworkServiceTests: XCTestCase {

    var service: EventLoggingNetworkService!
    private let testDomain = "upload-example.test"

    override func setUp() {
        super.setUp()
        self.service = EventLoggingNetworkService()
    }

    override func tearDown() {
        self.service = nil
        HTTPStubs.removeAllStubs()

        super.tearDown()
    }

    func testThatInvalidURLsFail() {
        let logFile = LogFile.containingRandomString()
        let req = URLRequest(url: URL(string: "invalid://location")!)

        waitForExpectation(timeout: 1.0) { exp in
            service.uploadFile(request: req, fileURL: logFile.url) { result in
                switch result {
                    case .success: XCTFail("This request should not be successful – the url is invalid")
                    case .failure(let error): XCTAssertNotNil(error)
                }

                exp.fulfill()
            }
        }
    }

    func testThatHTTPStatusCodesOutside200SeriesReturnError() {
        stubResponse(domain: testDomain, status: "server error", statusCode: 500)

        let logFile = LogFile.containingRandomString()
        let req = URLRequest(url: testURL())

        waitForExpectation(timeout: 1.0) { exp in
            service.uploadFile(request: req, fileURL: logFile.url) { result in
                switch result {
                    case .success: XCTFail("This request is not successful – the server is returning an error code")
                    case .failure(let error): XCTAssertNotNil(error)
                }

                exp.fulfill()
            }
        }
    }

    func testThatHTTPSuccessCodesReturnMessageBody() {
        let responseString = String.randomString(length: 255)
        stubResponse(domain: testDomain, status: responseString)

        let logFile = LogFile.containingRandomString()
        let req = URLRequest(url: testURL())

        waitForExpectation(timeout: 1.0) { exp in
            service.uploadFile(request: req, fileURL: logFile.url) { result in
                switch result {
                    case .success(let response):
                        let responseString = String(data: response!, encoding: .utf8)!
                        XCTAssertEqual(responseString, responseString)
                    case .failure: XCTFail("This request should not fail")
                }

                exp.fulfill()
            }
        }
    }

    func testThatHTTPErrorCodesReturnHttpStatus() {
        stubResponse(domain: testDomain, status: "rate limit exceeded", statusCode: 429)

        let logFile = LogFile.containingRandomString()
        let req = URLRequest(url: testURL())

        waitForExpectation(timeout: 1.0) { exp in
            service.uploadFile(request: req, fileURL: logFile.url) { result in
                switch result {
                    case .success: XCTFail("This request is not successful – the server is returning an error code")
                    case .failure(let error): XCTAssertEqual((error as NSError).code, 429)
                }

                exp.fulfill()
            }
        }
    }

    func testThatHTTPErrorCodesReturnHttpBodyAsUserInfo() {
        let title = UUID().uuidString
        let message = UUID().uuidString
        let code = Int.random(in: 400...499)
        stubErrorResponse(domain: testDomain, error: title, message: message, statusCode: Int32(code))

        let logFile = LogFile.containingRandomString()
        let req = URLRequest(url: testURL())

        waitForExpectation(timeout: 1.0) { exp in
            service.uploadFile(request: req, fileURL: logFile.url) { result in
                switch result {
                    case .success: XCTFail("This request is not successful – the server is returning an error code")
                    case .failure(let error):
                        XCTAssertEqual((error as NSError).code, code)
                        XCTAssertEqual((error as NSError).localizedDescription, title)
                        XCTAssertEqual((error as NSError).localizedFailureReason, message)
                }

                exp.fulfill()
            }
        }
    }


    fileprivate func testURL(path: String = #function) -> URL {
        return URL(string: "http://\(testDomain)/\(path)")!
    }
}
