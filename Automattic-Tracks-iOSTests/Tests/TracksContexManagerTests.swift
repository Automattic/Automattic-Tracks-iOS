@testable import AutomatticTracks
import XCTest

class TracksContextManagerTests: XCTestCase {

    func testStoreIsInDocumentsDirectoryByDefault() throws {
        let contextManager = TracksContextManager()
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Documents"))
    }

    func testStoreIsInApplicationSupportDirectoryWhenNotSandboxed() throws {
        let contextManager = TracksContextManager(sandboxedMode: false)
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Application Support"))
    }

    func testStoreIsInDocumentsDirectoryWhenSandboxed() throws {
        let contextManager = TracksContextManager(sandboxedMode: true)
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Documents"))
    }

    private func getStoreURLFrom(_ manager: TracksContextManager) throws -> URL {
        XCTAssertEqual(manager.persistentStoreCoordinator.persistentStores.count, 1)
        return try XCTUnwrap(manager.persistentStoreCoordinator.persistentStores.first?.url)
    }
}
