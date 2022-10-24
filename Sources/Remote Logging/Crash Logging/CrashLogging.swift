import Foundation
import Sentry

#if SWIFT_PACKAGE
import AutomatticTracksEvents
import AutomatticTracksModel
import AutomatticEncryptedLogs
#endif

/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    /// We haven't fully evicted global state from all of Tracks yet, so we keep a global reference around for now
    struct Internals {
        static var crashLogging: CrashLogging?
    }

    private let dataProvider: CrashLoggingDataProvider
    private let eventLogging: EventLogging?

    /// If you set this key to `true` in UserDefaults, crash logging will be
    /// sent even in DEBUG builds. If it is `false` or not present, then
    /// crash log events will only be sent in Release builds.
    public static let forceCrashLoggingKey = "force-crash-logging"

    // TODO: This could be made a configurable instance property, with default value in the `init`
    public static let eventsFlushingTimeout: TimeInterval = 15

    /// Initializes the crash logging system
    ///
    /// - Parameters:
    ///   - dataProvider: An object that provides any configuration to the crash logging system
    ///   - eventLogging: An associated `EventLogging` object that provides integration between the Crash Logging and Event Logging subsystems
    public init(dataProvider: CrashLoggingDataProvider, eventLogging: EventLogging? = nil) {
        self.dataProvider = dataProvider
        self.eventLogging = eventLogging
    }

    /// Starts the CrashLogging subsystem by initializing Sentry.
    ///
    /// Should be called as early as possible in the application lifecycle
    public func start() throws -> CrashLogging {

        /// Validate the DSN ourselves before initializing, because the SentrySDK silently prints the error to the log instead of telling us if the DSN is valid
        _ = try SentryDsn(string: self.dataProvider.sentryDSN)

        SentrySDK.start { options in
            options.dsn = self.dataProvider.sentryDSN

            options.debug = false
            options.diagnosticLevel = .error

            options.environment = self.dataProvider.buildType
            options.releaseName = self.dataProvider.releaseName
            options.enableAutoSessionTracking = self.dataProvider.shouldEnableAutomaticSessionTracking

            options.beforeSend = self.beforeSend

            /// Attach stack traces to non-fatal errors
            options.attachStacktrace = true

            // Performance monitoring options
            options.enableAutoPerformanceTracking = self.dataProvider.enableAutoPerformanceTracking
            options.tracesSampler = { _ in
                // To keep our implementation as Sentry agnostic as possible, we don't pass the
                // input `SamplingContext` down the chain.
                NSNumber(value: self.dataProvider.tracesSampler())
            }
            options.enableNetworkTracking = self.dataProvider.enableNetworkTracking
            options.enableFileIOTracking = self.dataProvider.enableFileIOTracking
            options.enableCoreDataTracking = self.dataProvider.enableCoreDataTracking
            #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
                options.enableUserInteractionTracing = self.dataProvider.enableUserInteractionTracing
                options.enableUIViewControllerTracking = self.dataProvider.enableUIViewControllerTracking
            #endif
        }

        Internals.crashLogging = self

        return self
    }

    func beforeSend(event: Sentry.Event?) -> Sentry.Event? {

        TracksLogDebug("📜 Firing `beforeSend`")

        #if DEBUG
        TracksLogDebug("📜 This is a debug build")
        let shouldSendEvent = UserDefaults.standard.bool(forKey: Self.forceCrashLoggingKey) && !dataProvider.userHasOptedOut
        #else
        let shouldSendEvent = !dataProvider.userHasOptedOut
        #endif

        /// If we shouldn't send the event we have nothing else to do here
        guard let event = event, shouldSendEvent else {
            return nil
        }

        if event.tags == nil {
            event.tags = [String: String]()
        }

        event.tags?["locale"] = NSLocale.current.languageCode

        /// Always provide a value in order to determine how often we're unable to retrieve application state
        event.tags?["app.state"] = ApplicationFacade().applicationState ?? "unknown"

        /// Read the current user from the Data Provider (though the Data Provider can decide not to provide it for functional or privacy reasons)
        event.user = dataProvider.currentUser?.sentryUser

        /// Everything below this line is related to event logging, so if it's not set up we can exit
        guard let eventLogging = self.eventLogging else {
            TracksLogDebug("📜 Cancelling log file attachment – Event Logging is not initialized")
            return event
        }

        eventLogging.attachLogToEventIfNeeded(event: event)

        return event
    }

    /// Immediately crashes the application and generates a crash report.
    public func crash() {
        SentrySDK.crash()
    }

    enum Errors: LocalizedError {
        case unableToConstructAuthStringError
    }
}

// MARK: - Manual Error Logging
public extension CrashLogging {

    ///
    /// Writes the error to the Crash Logging system, and includes a stack trace.
    ///
    /// - Parameters:
    ///   - error: The error object
    ///   - userInfo: A dictionary containing additional data about this error.
    ///   - level: The level of severity to report in Sentry (`.error` by default)
    func logError(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error) {

        let userInfo = userInfo ?? (error as NSError).userInfo

        let event = Event.from(
            error: error as NSError,
            level: level,
            extra: userInfo
        )

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

    /// Sends an `Event` to Sentry and triggers a callback on completion
    func logErrorImmediately(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error, callback: @escaping () -> Void) throws {
        try logErrorsImmediately([error], userInfo: userInfo, level: level, callback: callback)
    }

    func logErrorsImmediately(_ errors: [Error], userInfo: [String: Any]? = nil, level: SentryLevel = .error, callback: @escaping () -> Void) throws {

        errors.forEach { error in
            // Amending the global scope on a per-event basis seems like the best way to add the
            // caller-provided `userInfo` and `level`.
            SentrySDK.capture(error: error) { scope in
                // Under the hood, `setExtras` uses `NSMutableDictionary` `addEntriesFromDictionary`
                // meaning this won't replace the whole extras dictionary.
                scope.setExtras(userInfo)
                scope.setLevel(level)
            }
        }

        let queue = DispatchQueue(label: "com.automattic.tracks.flushSentry", qos: .background)
        queue.async {
            SentrySDK.flush(timeout: CrashLogging.eventsFlushingTimeout)
            callback()
        }
    }

    /**
     Writes the error to the Crash Logging system, and includes a stack trace. This method will block the thread until the event is fired.

     - Parameters:
     - error: The error object
     - userInfo: A dictionary containing additional data about this error.
     - level: The level of severity to report in Sentry (`.error` by default)
    */
    func logErrorAndWait(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error) throws {
        try logErrorImmediately(error, userInfo: userInfo, level: level) {
            TracksLogDebug("💥 Events flush completed. When using Sentry, this either mean all events were sent or that the flush timeout was reached.")
        }
    }
}

// MARK: - User Tracking
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

    func sentryUser(withData additionalUserData: [String: Any]) -> Sentry.User {
        let user = self.sentryUser
        user.data = additionalUserData
        return user
    }
}
