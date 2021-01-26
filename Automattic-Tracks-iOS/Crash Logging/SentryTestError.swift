import Foundation

public struct SentryTestError: LocalizedError {
    public let title: String
    public let code: Int

    public init(title: String, code: Int = -1) {
        self.title = title
        self.code = code
    }

    /// Provide a more obvious error description in Sentry than "The operation couldn't be completed."
    public var errorDescription: String? {
        "\(title) (code \(code))"
    }
}
