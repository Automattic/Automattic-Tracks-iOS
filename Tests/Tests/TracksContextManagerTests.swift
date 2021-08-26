@testable import AutomatticTracks
import XCTest

class TracksContextManagerTests: XCTestCase {

    func testStoreIsInApplicationSupportDirectory() throws {
        let contextManager = TracksContextManager()
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Application Support"))
    }

    private func getStoreURLFrom(_ manager: TracksContextManager) throws -> URL {
        XCTAssertEqual(manager.persistentStoreCoordinator.persistentStores.count, 1)
        return try XCTUnwrap(manager.persistentStoreCoordinator.persistentStores.first?.url)
    }
}
