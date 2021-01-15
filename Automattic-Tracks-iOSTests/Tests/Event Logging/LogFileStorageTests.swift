import XCTest
import Combine
@testable import AutomatticTracks

@available(iOS 13.0, *)
class MockDirectoryMonitor: DirectoryMonitorProtocol {
    var contents: [URL] = []

    var files = PassthroughSubject<[URL], Never>()

    func send(urls: [URL]) {
        contents = urls
        files.send(urls)
    }
}

@available(iOS 13.0, OSX 10.15, *)
class LogFileStorageTests: XCTestCase {

    private var cancellable: AnyCancellable?

    override func tearDownWithError() throws {
        cancellable?.cancel()
        super.tearDown()
    }

    func testThatLogFilePublisherUsesFileNameAsUUID() {
        let uuid = UUID().uuidString
        let url = sampleUrl(withUuid: uuid)
        let monitor = MockDirectoryMonitor()
        let storage = LogFileStorage(url: url, eventLogging: EventLogging(dataSource: MockEventLoggingDataSource(), delegate: MockEventLoggingDelegate()), monitor: monitor)

        waitForExpectation { exp in
            cancellable = storage.$logFiles.sink { logFiles in
                if !logFiles.isEmpty {
                    XCTAssertEqual(uuid, logFiles.first?.uuid)
                    exp.fulfill()
                }
            }

            monitor.send(urls: [url])
        }
    }

    /// Test Helpers
    private func sampleUrl(withUuid uuid: String) -> URL {
        return FileManager.default.createTempFile(named: uuid, containing: uuid)
    }
}
