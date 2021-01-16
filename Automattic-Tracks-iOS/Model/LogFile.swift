import Foundation

public struct LogFile {
    public let uuid: String
    public let url: URL

    public init(url: URL, uuid: String = UUID().uuidString) {
        self.url = url
        self.uuid = uuid
    }

    var fileName: String {
        return uuid
    }

    static func fromExistingFile(at url: URL) -> LogFile {
        return LogFile(url: url, uuid: url.lastPathComponent)
    }

    var creationDate: Date? {
        try? FileManager.default.attributesOfItem(at: url).creationDate
    }
}

extension LogFile: Comparable {
    public static func < (lhs: LogFile, rhs: LogFile) -> Bool {
        guard
            let lhsDate = lhs.creationDate,
            let rhsDate = rhs.creationDate
        else {
                return false
        }

        return lhsDate > rhsDate
    }
}

extension LogFile: Identifiable {
    public var id: String {
        return uuid
    }
}
