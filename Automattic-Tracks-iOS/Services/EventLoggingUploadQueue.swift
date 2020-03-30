import Foundation

class EventLoggingUploadQueue {

    private let fileManager: FileManager
    var storageDirectory: URL

    init(storageDirectory: URL? = nil, fileManager: FileManager = FileManager.default) {
        let defaultStorageDirectory = fileManager.documentsDirectory.appendingPathComponent("log-upload-queue")
        self.storageDirectory = storageDirectory ?? defaultStorageDirectory
        self.fileManager = fileManager
    }

    /// The log file on top of the queue
    var first: LogFile? {
        guard let url = try? fileManager.contentsOfDirectory(at: storageDirectory).first else {
            return nil
        }

        return LogFile.fromExistingFile(at: url)
    }

    func add(_ log: LogFile) throws {
        try createStorageDirectoryIfNeeded()
        try fileManager.copyItem(at: log.url, to: storageDirectory.appendingPathComponent(log.fileName))
    }

    func remove(_ log: LogFile) throws {
        let url = storageDirectory.appendingPathComponent(log.fileName)
        if fileManager.fileExistsAtURL(url) {
            try fileManager.removeItem(at: url)
        }
    }

    func createStorageDirectoryIfNeeded() throws {
        if !fileManager.directoryExistsAtURL(storageDirectory) {
            try fileManager.createDirectory(at: storageDirectory, withIntermediateDirectories: true, attributes: nil)
        }
    }
}
