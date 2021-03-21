import XCTest
import Combine
@testable import AutomatticTracks

@available(iOS 13.0, OSX 10.15, *)
class DirectoryMonitorTests: XCTestCase {

    var currentTempDirectory: URL!
    var cancellable: AnyCancellable?

    override func setUpWithError() throws {
        try super.setUpWithError()

        currentTempDirectory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: currentTempDirectory!, withIntermediateDirectories: true, attributes: nil)
    }

    override func tearDownWithError() throws {
        cancellable?.cancel()
        try FileManager.default.removeItem(at: currentTempDirectory!)

        super.tearDown()
    }

    func testThatDirectoryMonitorNotifiesOfNewFilesInDirectory() throws {

        let monitor = DirectoryMonitor(url: currentTempDirectory)

        try waitForExpectation { exp in
            cancellable = monitor.files.eraseToAnyPublisher().sink { urls in
                if urls.count == 1 {
                    exp.fulfill()
                }
            }

            try createFileInTempDirectory()
        }
    }

    func testThatDirectoryMonitorNotifiesOfRemovedFilesInDirectory() throws {

        let monitor = DirectoryMonitor(url: currentTempDirectory)
        let fileUrl = try createFileInTempDirectory()

        try waitForExpectation { exp in

            cancellable = monitor.files.eraseToAnyPublisher().sink { urls in
                if urls.isEmpty {
                    exp.fulfill()
                }
            }

            debugPrint("About to remove file")
            try removeFile(at: fileUrl)
            debugPrint("Deleted file")
        }
    }

    /// Test Helpers
    @discardableResult
    private func createFileInTempDirectory() throws -> URL {
        let uuid = UUID().uuidString
        let fileUrl = currentTempDirectory!.appendingPathComponent(uuid)
        try uuid.write(to: fileUrl, atomically: true, encoding: .utf8)

        return fileUrl
    }

    private func removeFile(at url: URL) throws {
        try FileManager.default.removeItem(at: url)
    }
}
