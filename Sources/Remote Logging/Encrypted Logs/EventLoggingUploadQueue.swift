import Foundation

#if SWIFT_PACKAGE
import AutomatticTracksModel
#endif

class EventLoggingUploadQueue {

    private let fileManager: FileManager
    var storageDirectory: URL

    init(storageDirectory: URL, retentionDays: Int = 30, fileManager: FileManager = FileManager.default) {
        self.storageDirectory = storageDirectory
        self.fileManager = fileManager

        try? self.clean(retentionDays: retentionDays)
    }

    /// Get all items
    var items: [LogFile] {
        let items = try? fileManager.contentsOfDirectory(at: storageDirectory).map {
            return LogFile.fromExistingFile(at: $0)
        }.sorted()

        return items ?? []
    }

    /// The log file on top of the queue
    var first: LogFile? {
        return items.first
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

    /// Ensure that logs don't pile up on the user's device if for some reason they can't be uploaded
    func clean(retentionDays: Int) throws {

        let date = Calendar.current.date(byAdding: .day, value: retentionDays * -1, to: Date())!
        let preservationRange = (date ... Date())

        try fileManager.contentsOfDirectory(at: storageDirectory)
            .filter {
                guard let fileCreationDate = try fileManager.attributesOfItem(at: $0).fileCreationDate else {
                    return true // to be safe, remove any file that has inaccessible file attributes
                }

                return !preservationRange.contains(fileCreationDate)
            }
            .forEach {
                try fileManager.removeItem(at: $0)
            }
    }
}
