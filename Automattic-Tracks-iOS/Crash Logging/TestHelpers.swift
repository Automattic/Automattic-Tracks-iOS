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
