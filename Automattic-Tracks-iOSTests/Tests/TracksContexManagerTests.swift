@testable import AutomatticTracks
import XCTest

class TracksContextManagerTests: XCTestCase {

    func testStoreIsInApplicationSupportDirectory() throws {
        let contextManager = TracksContextManager()

        XCTAssertEqual(contextManager.persistentStoreCoordinator.persistentStores.count, 1)
        let storeURL = try XCTUnwrap(contextManager.persistentStoreCoordinator.persistentStores.first?.url)

        XCTAssertTrue(storeURL.pathComponents.contains("Application Support"))
    }
}
