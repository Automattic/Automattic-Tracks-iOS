import Foundation

public class LogFile {
    var uuid: String
    var url: URL

    public init(url: URL, uuid: String = UUID().uuidString) {
        self.url = url
        self.uuid = uuid
    }

    var exists: Bool {
         return FileManager.default.fileExists(atPath: url.path)
    }
}
