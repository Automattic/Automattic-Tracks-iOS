import XCTest
@testable import AutomatticTracks

class EventLoggingUploadQueueTests: XCTestCase {

    var uploadQueue = EventLoggingUploadQueue()

    override func setUp() {
        uploadQueue = EventLoggingUploadQueue()
    }

    override func tearDown() {
        super.tearDown()
        let directory = uploadQueue.storageDirectory
        if FileManager.default.directoryExistsAtURL(directory) {
            try! FileManager.default.removeItem(at: directory)
        }

        XCTAssertTrue(!FileManager.default.directoryExistsAtURL(directory))
    }

    func testThatEmptyStorageDirectoryReturnsNilForFirstFile() {
        XCTAssertNil(uploadQueue.first)
    }

    func testThatAddingAFileCreatesStorageDirectory() {
        let log = LogFile.containingRandomString()
        try! uploadQueue.add(log)
        XCTAssertTrue(FileManager.default.directoryExistsAtURL(uploadQueue.storageDirectory))
    }

    func testThatAddingAFileCopiesItToStorageDirectory() {
        let log = LogFile.containingRandomString()
        try! uploadQueue.add(log)

        let files = (try? FileManager.default.contentsOfDirectory(at: uploadQueue.storageDirectory)) ?? []
        XCTAssertTrue(files.count == 1)
    }

    func testThatAddingAFileMakesItAvailableForRetrieval() {
        let log = LogFile.containingRandomString()
        try! uploadQueue.add(log)

        guard let firstLog = uploadQueue.first else {
            XCTFail("The queue must contain at least one log")
            return
        }

        XCTAssertEqual(FileManager.default.contents(atUrl: log.url), FileManager.default.contents(atUrl: firstLog.url))
    }

    func testThatRemovingAFileRemovesItFromStorage() {
        let log = LogFile.containingRandomString()
        try! uploadQueue.add(log)

        XCTAssertEqual(try! FileManager.default.contentsOfDirectory(at: uploadQueue.storageDirectory).count, 1)
        try! uploadQueue.remove(log)
        XCTAssertEqual(try! FileManager.default.contentsOfDirectory(at: uploadQueue.storageDirectory).count, 0)
    }

    func testThatCustomFileUploadQueueLocationCreatesStorageDirectory() {
        let log = LogFile.containingRandomString()

        let customLocation = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
        let customQueue = EventLoggingUploadQueue(storageDirectory: customLocation)
        try! customQueue.add(log)

        XCTAssert(FileManager.default.fileExistsAtURL(log.url))
    }
}
