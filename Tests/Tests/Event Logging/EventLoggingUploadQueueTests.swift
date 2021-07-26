import XCTest

#if SWIFT_PACKAGE
@testable import AutomatticRemoteLogging
#else
@testable import AutomatticTracks
#endif


class EventLoggingUploadQueueTests: XCTestCase {

    var uploadQueue: EventLoggingUploadQueue!

    override func setUp() {
        super.setUp()

        uploadQueue = EventLoggingUploadQueue(storageDirectory: MockEventLoggingDataSource().logUploadQueueStorageURL)
    }

    override func tearDown() {
        let directory = uploadQueue.storageDirectory
        if FileManager.default.directoryExistsAtURL(directory) {
            try! FileManager.default.removeItem(at: directory)
        }

        XCTAssertTrue(!FileManager.default.directoryExistsAtURL(directory))

        uploadQueue = nil

        super.tearDown()
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

    func testThatUploadQueueRetainsCorrectNumberOfLogFiles() {

        let directory = FileManager.default.documentsDirectory.appendingPathComponent(UUID().uuidString)
        let queue = EventLoggingUploadQueue(storageDirectory: directory)

        (0..<90).forEach { _ in
            try! queue.add(LogFile.containingRandomString())
        }

        XCTAssertEqual(queue.items.count, 90)

        queue.items.enumerated().forEach {
            try! FileManager.default.setAttributesOfItem(attributes: [
                FileAttributeKey.creationDate: Calendar.current.date(byAdding: .day, value: $0.offset * -1, to: Date())!
            ], at: $0.element.url)
        }

        let retain = Int.random(in: 1..<89)
        try! queue.clean(retentionDays: retain)

        XCTAssertEqual(queue.items.count, retain)
    }
}
