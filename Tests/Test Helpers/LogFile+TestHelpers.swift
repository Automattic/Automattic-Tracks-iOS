import Foundation

#if SWIFT_PACKAGE
import AutomatticRemoteLogging
import AutomatticEncryptedLogs
#else
import AutomatticTracks
#endif

extension LogFile {

    init(containing string: String) {
        let uuid = UUID().uuidString
        let url = FileManager.default.createTempFile(named: uuid, containing: string)

        self.init(url: url, uuid: uuid)
    }

    static func containingRandomString(length: Int = 128) -> LogFile {
        return LogFile(containing: String.randomString(length: length))
    }

    static func withInvalidPath() -> LogFile {
        return LogFile(url: URL(fileURLWithPath: "invalid"))
    }
}
