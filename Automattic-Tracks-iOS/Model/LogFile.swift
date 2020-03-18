import Foundation

public struct LogFile {
    let uuid: String
    let url: URL

    public init(url: URL, uuid: String = UUID().uuidString) {
        self.url = url
        self.uuid = uuid
    }
}
