import Foundation
import Sentry

public struct TracksUser {
    let userID: String?
    let email: String?
    let username: String?

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

internal extension TracksUser {

    var sentryUser: Sentry.User {

        let user = Sentry.User()

        if let userID = self.userID {
            user.userId = userID
        }

        if let email = self.email {
            user.email = email
        }

        if let username = user.username {
            user.username = username
        }

        return user
    }

    func sentryUser(withData additionalUserData: [String : Any]) -> Sentry.User {
        let user = self.sentryUser
        user.extra = additionalUserData
        return user
    }
}
