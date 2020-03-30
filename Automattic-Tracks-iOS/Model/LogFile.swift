import Foundation

public struct LogFile {
    let uuid: String
    let url: URL

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
}
