import XCTest
@testable import AutomatticTracks
import Sentry

class SentryExtensionTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testThatEventInitializationReturnsEnglishErrorDescription() {
        do {
            _ = try FileManager.default.attributesOfItem(at: URL(fileURLWithPath: "/not-a-real-path"))
        } catch let err {
            let event = Event.from(error: err as NSError)
            XCTAssertEqual(event.message.formatted, "Error Domain=NSPOSIXErrorDomain Code=2 \"No such file or directory\"")
        }
    }
}
