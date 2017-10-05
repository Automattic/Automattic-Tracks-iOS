import XCTest
import AutomatticTracks
import OHHTTPStubs

class TracksServiceRemoteTests: XCTestCase {
    var subject: TracksServiceRemote!

    override func setUp() {
        super.setUp()

        subject = TracksServiceRemote()
    }
    
    override func tearDown() {
        super.tearDown()

        subject = nil
        OHHTTPStubs.removeAllStubs()
    }

    func testSendBatchOfEventsAcceptedResponse() {
        let expect = expectation(description: "Tracks events expectation")

        let events = [TracksEvent]()

        stub(condition: isHost("public-api.wordpress.com")) { _ in
            let stubData = "\"Accepted\"".data(using: String.Encoding.utf8)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatch(of: events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expect.fulfill()

            XCTAssertNil(error)
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testSendBatchOfEventsInvalidResponse() {
        let expect = expectation(description: "Tracks events expectation")

        let events = [TracksEvent]()

        stub(condition: isHost("public-api.wordpress.com")) { _ in
            let stubData = "".data(using: String.Encoding.utf8)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatch(of: events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expect.fulfill()
            XCTAssertNotNil(error)

            if let error = error as NSError? {
                XCTAssertEqual(TracksErrorDomain, error.domain)
                XCTAssertEqual(TracksErrorCode.remoteResponseInvalid.rawValue, error.code)
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }

    func testSendBatchOfEventsErrorResponse500() {
        let expect = expectation(description: "Tracks events expectation")

        let events = [TracksEvent]()

        stub(condition: isHost("public-api.wordpress.com")) { _ in
            let stubData = "".data(using: String.Encoding.utf8)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 500, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatch(of: events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expect.fulfill()
            XCTAssertNotNil(error)

            if let error = error as NSError? {
                XCTAssertEqual(TracksErrorDomain, error.domain)
                XCTAssertEqual(TracksErrorCode.remoteResponseError.rawValue, error.code)
            }
        }

        waitForExpectations(timeout: 2.0, handler: nil)
    }
}
