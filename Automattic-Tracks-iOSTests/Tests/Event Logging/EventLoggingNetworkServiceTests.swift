import XCTest
@testable import AutomatticTracks
import OHHTTPStubs

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

    func testThatHTTPSucessCodesReturnMessageBody() {
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

    fileprivate func testURL(path: String = #function) -> URL {
        return URL(string: "http://\(testDomain)/\(path)")!
    }
}
