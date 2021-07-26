import Foundation
import Sentry

public struct TracksUser {
    public let userID: String?
    public let email: String?
    public let username: String?

    public init(userID: String?, email: String?, username: String?) {
        self.userID = userID
        self.email = email
        self.username = username
    }

    public init(email: String) {
        self.userID = nil
        self.email = email
        self.username = nil
    }
}
