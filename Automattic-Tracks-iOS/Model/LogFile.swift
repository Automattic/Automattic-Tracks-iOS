import Foundation

public struct LogFile {
    public let uuid: String
    public let url: URL
    public let date: Date?

    public init(url: URL, uuid: String = UUID().uuidString) {
        self.url = url
        self.uuid = uuid
        self.date = try? FileManager.default.attributesOfItem(at: url).fileCreationDate
    }

    var fileName: String {
        return uuid
    }

    static func fromExistingFile(at url: URL) -> LogFile {
        return LogFile(url: url, uuid: url.lastPathComponent)
    }
}

extension LogFile: Comparable {
    public static func < (lhs: LogFile, rhs: LogFile) -> Bool {
        guard
            let lhsDate = try? FileManager.default.attributesOfItem(at: lhs.url).fileCreationDate,
            let rhsDate = try? FileManager.default.attributesOfItem(at: rhs.url).fileCreationDate
        else {
                return false
        }

        return lhsDate < rhsDate
    }
}

extension LogFile: Identifiable {
    public typealias ID = String
    public var id: String {
        return uuid
    }
}
