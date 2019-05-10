import Foundation
import Sentry

public struct CrashLoggingUser {
    let userID: String?
    let email: String?
    let username: String?
    let isLoggedIn: Bool

    public init(userID: String?, email: String?, username: String?, isLoggedIn: Bool = false) {
        self.userID = userID
        self.email = email
        self.username = username
        self.isLoggedIn = isLoggedIn
    }
}

extension Sentry.User {

    convenience init(user: CrashLoggingUser?, additionalUserData: [String : Any]) {

        let userID = user?.userID ?? "0"
        let username = user?.username ?? "anonymous"

        self.init(userId: username)
        email = user?.email

        /// Merge provided user data with some defaults, overwriting those defaults
        /// in favour of values provided by the application.
        extra = additionalUserData.merging([
            "user_id": userID,
        ]) { (application_value, library_value) in application_value }
    }
}
