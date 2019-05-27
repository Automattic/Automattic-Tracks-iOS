import Foundation
import ObjectiveC
import Sentry

typealias EventLoggingCallback = (Event) -> ()
typealias DecisionCallback = (Bool) -> ()

private var errorLoggingCallback: EventLoggingCallback? = nil
private var messageLoggingCallback: EventLoggingCallback? = nil
private var eventSendCallback: DecisionCallback? = nil

internal extension CrashLoggingDataProvider {

    var didLogErrorCallback: EventLoggingCallback? {
        get { return errorLoggingCallback }
        set { errorLoggingCallback = newValue }
    }

    var didLogMessageCallback: EventLoggingCallback? {
        get { return messageLoggingCallback }
        set { messageLoggingCallback = newValue }
    }
}

internal extension CrashLogging {

    var environment: String? {
        return Client.shared?.environment
    }

    var cachedUser: TracksUser? {
        guard
            let context = currentContext,
            let userData = context["user"] as? [String : Any]
        else { return nil }

        let userID = userData["id"] as? String
        let email = userData["email"] as? String
        let username = userData["username"] as? String

        return TracksUser(userID: userID, email: email, username: username)
    }

    /// Refresh the context from disk, then return it
    var currentContext: [String : Any]? {
        Client.shared?.perform(Selector(("restoreContextBeforeCrash")))
        return Client.shared?.lastContext
    }

    var shouldSendEventCallback: DecisionCallback? {
        get { return eventSendCallback }
        set { eventSendCallback = newValue }
    }
}
