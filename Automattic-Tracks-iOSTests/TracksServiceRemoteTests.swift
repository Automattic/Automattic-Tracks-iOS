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

    func testSendBatchOfEvents() {
        let expectation = expectationWithDescription("Tracks events expectation")

        let events = [TracksEvent]()

        stub(isHost("public-api.wordpress.com")) { _ in
            print("WHOOOOOOOOOOOOOOOO")
            let stubData = "\"Accepted\"".dataUsingEncoding(NSUTF8StringEncoding)
            return OHHTTPStubsResponse(data: stubData!, statusCode: 200, headers: ["Content-Type": "application/json"])
        }

        subject.sendBatchOfEvents(events, withSharedProperties: [NSObject : AnyObject]()) {
            error in
            expectation.fulfill()
        }

        waitForExpectationsWithTimeout(2.0, handler: nil)
    }
}
