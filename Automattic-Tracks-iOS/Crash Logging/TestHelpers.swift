import Foundation
import ObjectiveC
import Sentry

typealias EventLoggingCallback = (Event) -> ()
typealias ShouldSendEventCallback = (Event?, Bool) -> ()

private var errorLoggingCallback: EventLoggingCallback? = nil
private var messageLoggingCallback: EventLoggingCallback? = nil
private var eventSendCallback: ShouldSendEventCallback? = nil

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

    var cachedUser: TracksUser? {
        guard let userData = SentrySDK.currentHub().getScope().serialize()["user"] as? [String: Any] else { return nil }

        let userID = userData["id"] as? String
        let email = userData["email"] as? String
        let username = userData["username"] as? String

        return TracksUser(userID: userID, email: email, username: username)
    }

    var shouldSendEventCallback: ShouldSendEventCallback? {
        get { return eventSendCallback }
        set { eventSendCallback = newValue }
    }
}
