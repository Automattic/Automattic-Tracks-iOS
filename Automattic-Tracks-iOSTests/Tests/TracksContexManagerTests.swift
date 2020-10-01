@testable import AutomatticTracks
import XCTest

class TracksContextManagerTests: XCTestCase {

    func testStoreIsInDocumentsDirectoryByDefault() throws {
        let contextManager = TracksContextManager()
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Application Support"))
    }

    func testStoreIsInApplicationSupportDirectoryWhenSandboxed() throws {
        let contextManager = TracksContextManager(sandboxedMode: true)
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Application Support"))
    }

    func testStoreIsInDocumentsDirectoryWhenNotSandboxed() throws {
        let contextManager = TracksContextManager(sandboxedMode: false)
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Documents"))
    }

    private func getStoreURLFrom(_ manager: TracksContextManager) throws -> URL {
        XCTAssertEqual(manager.persistentStoreCoordinator.persistentStores.count, 1)
        return try XCTUnwrap(manager.persistentStoreCoordinator.persistentStores.first?.url)
    }
}
