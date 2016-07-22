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
        let expectation = expectationWithDescription("Tracks events expectation")

        let events = [TracksEvent]()

        stub(isHost("public-api.wordpress.com")) { _ in
            let stubData = "\"Accepted\"".dataUsingEncoding(NSUTF8StringEncoding)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatchOfEvents(events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expectation.fulfill()

            XCTAssertNil(error)
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testSendBatchOfEventsInvalidResponse() {
        let expectation = expectationWithDescription("Tracks events expectation")

        let events = [TracksEvent]()

        stub(isHost("public-api.wordpress.com")) { _ in
            let stubData = "".dataUsingEncoding(NSUTF8StringEncoding)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatchOfEvents(events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expectation.fulfill()

            XCTAssertNotNil(error)
            XCTAssertEqual(TracksErrorDomain, error?.domain)
            XCTAssertEqual(TracksErrorCode.RemoteResponseInvalid.rawValue, error?.code)
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }

    func testSendBatchOfEventsErrorResponse500() {
        let expectation = expectationWithDescription("Tracks events expectation")

        let events = [TracksEvent]()

        stub(isHost("public-api.wordpress.com")) { _ in
            let stubData = "".dataUsingEncoding(NSUTF8StringEncoding)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 500, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatchOfEvents(events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expectation.fulfill()

            XCTAssertNotNil(error)
            XCTAssertEqual(TracksErrorDomain, error?.domain)
            XCTAssertEqual(TracksErrorCode.RemoteResponseError.rawValue, error?.code)
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}
