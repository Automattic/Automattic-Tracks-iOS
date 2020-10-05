@testable import AutomatticTracks
import XCTest

class TracksContextManagerTests: XCTestCase {

    func testStoreIsInDocumentsDirectoryByDefault() throws {
        try XCTSkipIf(platformIsMacOS(), "Skipping on macOS because tests run outside of sandbox from CLI and would require access to the Documents folder and may crash if that's not granted")
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
        try XCTSkipIf(platformIsMacOS(), "Skipping on macOS because tests run outside of sandbox from CLI and would require access to the Documents folder and may crash if that's not granted")
        let contextManager = TracksContextManager(sandboxedMode: true)
        let storeURL = try getStoreURLFrom(contextManager)
        XCTAssertTrue(storeURL.pathComponents.contains("Documents"))
    }

    private func getStoreURLFrom(_ manager: TracksContextManager) throws -> URL {
        XCTAssertEqual(manager.persistentStoreCoordinator.persistentStores.count, 1)
        return try XCTUnwrap(manager.persistentStoreCoordinator.persistentStores.first?.url)
    }

    private func platformIsMacOS() -> Bool {
        #if os(macOS)
        return true
        #else
        return false
        #endif
    }
}
