import XCTest

#if SWIFT_PACKAGE
@testable import AutomatticRemoteLogging
#else
@testable import AutomatticTracks
#endif


class LogFileTests: XCTestCase {

    func testThatLogFileNameMatchesUUID() {
        let log = LogFile.containingRandomString()
        XCTAssertEqual(log.fileName, log.uuid)
    }

    func testParsingExistingFilenameUsesOnlyFilename() {
        let fileName = UUID().uuidString
        let contents = String.randomString(length: 255)
        let testFile = FileManager.default.createTempFile(named: fileName, containing: contents)

        let log = LogFile.fromExistingFile(at: testFile)
        XCTAssertEqual(log.fileName, fileName)
        XCTAssertEqual(log.uuid, fileName)
    }

    func testParsingExistingFilenameUsesOnlyFilenameIncludingExtension() {
        let contents = String.randomString(length: 255)
        let testFile = FileManager.default.createTempFile(named: "test.log", containing: contents)

        let log = LogFile.fromExistingFile(at: testFile)
        XCTAssertEqual(log.fileName, "test.log")
        XCTAssertEqual(log.uuid, "test.log")
    }
}
