import Foundation
import Sodium
@testable import AutomatticTracks

typealias LogFileCallback = (LogFile) -> ()
typealias ErrorWithLogFileCallback = (Error, LogFile) -> ()

enum MockError: Error {
    case generic
}

class MockLogFile: LogFile {
    init(string: String) {
        let uuid = UUID().uuidString
        let logFileURL = FileManager.default.createTempFile(named: uuid, containing: string)
        super.init(url: logFileURL, uuid: uuid)
    }

    static var withRandomString: LogFile {
        return MockLogFile(string: String.randomString(length: 128))
    }
}
