import Foundation
import AutomatticTracks

extension LogFile {

    init(containing string: String) {
        let uuid = UUID().uuidString
        let url = FileManager.default.createTempFile(named: uuid, containing: string)

        self.init(url: url, uuid: uuid)
    }

    static func containingRandomString(length: Int = 128) -> LogFile {
        return LogFile(containing: String.randomString(length: length))
    }
}
