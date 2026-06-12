@testable import AutomatticTracks
import XCTest

class TracksContextManagerTests: XCTestCase {

    func testStoreIsInExpectedDirectory() throws {
        let contextManager = TracksContextManager()
        let storeURL = try getStoreURLFrom(contextManager)

        // tvOS only allows apps to write to Caches and the temporary directory, so the store lives
        // in Caches there instead of Application Support.
        #if os(tvOS)
        XCTAssertTrue(storeURL.pathComponents.contains("Caches"))
        #else
        XCTAssertTrue(storeURL.pathComponents.contains("Application Support"))
        #endif

        XCTAssertEqual(storeURL.lastPathComponent, "Tracks.sqlite")
    }

    private func getStoreURLFrom(_ manager: TracksContextManager) throws -> URL {
        XCTAssertEqual(manager.persistentStoreCoordinator.persistentStores.count, 1)
        return try XCTUnwrap(manager.persistentStoreCoordinator.persistentStores.first?.url)
    }
}
