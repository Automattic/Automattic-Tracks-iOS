import Foundation
import Sentry
import CocoaLumberjack

struct CrashLoggingInternals {
    static var crashLogging: CrashLogging?
}

/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    private let dataProvider: CrashLoggingDataProvider
    private let eventLogging: EventLogging?

    public init(dataProvider: CrashLoggingDataProvider, eventLogging: EventLogging? = nil) {
        self.dataProvider = dataProvider
        self.eventLogging = eventLogging
    }

    public func start() throws -> CrashLogging {

        /// Validate the DSN ourselves before initializing, because the SentrySDK silently prints the error to the log instead of telling us if the DSN is valid
        _ = try SentryDsn(string: self.dataProvider.sentryDSN)

        SentrySDK.start { options in
            options.dsn = self.dataProvider.sentryDSN
            options.debug = true // Helpful to see what's going on

            options.environment = self.dataProvider.buildType
            options.releaseName = self.dataProvider.releaseName
            options.enableAutoSessionTracking = self.dataProvider.shouldEnableAutomaticSessionTracking

            options.beforeSend = self.beforeSend

            /// Attach stack traces to non-fatal errors
            options.attachStacktrace = true
        }

        CrashLoggingInternals.crashLogging = self

        return self
    }

    func beforeSend(event: Sentry.Event?) -> Sentry.Event? {
        guard let event = event else {
            return nil
        }

        DDLogDebug("📜 Firing `beforeSend`")

        if event.tags == nil {
            event.tags = [String: String]()
        }

        event.tags?["locale"] = NSLocale.current.languageCode

        /// Always provide a value in order to determine how often we're unable to retrieve the value
        event.tags?["app.state"] = ApplicationFacade().applicationState ?? "unknown"

        #if DEBUG
        DDLogDebug("📜 This is a debug build")
        let shouldSendEvent = UserDefaults.standard.bool(forKey: "force-crash-logging")
        #else
        let shouldSendEvent = !dataProvider.userHasOptedOut
        #endif

        /// If we shouldn't send the event we have nothing else to do here
        guard shouldSendEvent else {
            return nil
        }

        /// Read the current user from the Data Provider (though the Data Provider can decide not to provide it for functional or privacy reasons)
        event.user = dataProvider.currentUser?.sentryUser

        /// Everything below this line is related to event logging, so if it's not set up we can exit
        guard let eventLogging = self.eventLogging else {
            DDLogDebug("📜 Cancelling log file attachment – Event Logging is not initialized")
            return event
        }

        eventLogging.attachLogToEventIfNeeded(event: event)

        return event
    }

    /// Immediately crashes the application and generates a crash report.
    public static func crash() {
        SentrySDK.crash()
    }
}

// Manual Error Logging
public extension CrashLogging {

    ///
    /// Writes the error to the Crash Logging system, and includes a stack trace.
    /// - Parameters:
    ///   - error: The error object
    ///   - userInfo: A dictionary containing additional data about this error.
    ///   - level: The level of severity to report in Sentry (`.error` by default)
    func logError(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error) {

        let event = Event(level: level)

        /// Use the unlocalized error message for better grouping
        event.message = SentryMessage(formatted: (error as NSError).description)

        /// If the developer provides their own userInfo, use that – otherwise read it from the Error
        event.extra = userInfo ?? (error as NSError).userInfo

        /// Attach the localized description in case it has additional data
        event.extra?["localized-description"] = error.localizedDescription

        event.timestamp = Date()

        SentrySDK.capture(event: event)
        dataProvider.didLogErrorCallback?(event)
    }

    /// Writes a message to the Crash Logging system, and includes a stack trace.
    ///
    /// - Parameters:
    ///   - message: The message
    ///   - properties: A dictionary containing additional information about this error
    ///   - level: The level of severity to report in Sentry (`.info` by default)
    func logMessage(_ message: String, properties: [String: Any]? = nil, level: SentryLevel = .info) {

        let event = Event(level: level)
        event.message = SentryMessage(formatted: message)
        event.extra = properties
        event.timestamp = Date()

        SentrySDK.capture(event: event)
        dataProvider.didLogMessageCallback?(event)
    }
}

// User Tracking
extension CrashLogging {

    internal var currentUser: Sentry.User {

        let anonymousUser = TracksUser(userID: nil, email: nil, username: nil).sentryUser

        /// Don't continue if the data source doesn't yet have a user
        guard let user = dataProvider.currentUser else { return anonymousUser }
        let data = dataProvider.additionalUserData

        return user.sentryUser(withData: data)
    }

    /// Causes the Crash Logging System to refresh its knowledge about the current state of the system.
    ///
    /// This is required in situations like login / logout, when the system otherwise might not
    /// know a change has occured.
    ///
    /// Calling this method in these situations prevents
    public func setNeedsDataRefresh() {
        SentrySDK.setUser(currentUser)
    }
}

// Event Logging
extension Event {

    private static let logIDKey = "logID"

    var logID: String? {
        get {
            return self.extra?[Event.logIDKey] as? String
        }
        set {
            self.extra?[Event.logIDKey] = newValue
        }
    }
}
