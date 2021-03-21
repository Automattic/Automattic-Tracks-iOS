import Foundation

public struct SentryTestError: LocalizedError {
    public let title: String
    public let code: Int

    public init(title: String, code: Int = -1) {
        self.title = title
        self.code = code
    }
}
