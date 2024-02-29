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

    public let flushTimeout: TimeInterval

    /// Initializes the crash logging system
    ///
    /// - Parameters:
    ///   - dataProvider: An object that provides any configuration to the crash logging system
    ///   - eventLogging: An associated `EventLogging` object that provides integration between the Crash Logging and Event Logging subsystems
    ///   - flushTimeout: The `TimeInterval` to wait for when flushing events and crahses queued to be sent to the remote
    public init(
        dataProvider: CrashLoggingDataProvider,
        eventLogging: EventLogging? = nil,
        flushTimeout: TimeInterval = 15
    ) {
        self.dataProvider = dataProvider
        self.eventLogging = eventLogging
        self.flushTimeout = flushTimeout
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
            options.enableAutoSessionTracking = self.dataProvider.shouldEnableAutomaticSessionTracking
            options.enableAppHangTracking = self.dataProvider.enableAppHangTracking
            options.enableCaptureFailedRequests = self.dataProvider.enableCaptureFailedRequests

            options.beforeSend = self.beforeSend

            /// Attach stack traces to non-fatal errors
            options.attachStacktrace = true

            // Events
            options.sampleRate = NSNumber(value: min(max(self.dataProvider.errorEventsSamplingRate, 0), 1))

            // Performance monitoring options
            options.enableAutoPerformanceTracing = self.dataProvider.enableAutoPerformanceTracking
            options.tracesSampler = { _ in
                // To keep our implementation as Sentry agnostic as possible, we don't pass the
                // input `SamplingContext` down the chain.
                NSNumber(value: self.dataProvider.tracesSampler())
            }
            options.profilesSampleRate = NSNumber(value: self.dataProvider.profilingRate)
            options.enableNetworkTracking = self.dataProvider.enableNetworkTracking
            options.enableFileIOTracing = self.dataProvider.enableFileIOTracking
            options.enableCoreDataTracing = self.dataProvider.enableCoreDataTracking
            #if os(iOS) || os(tvOS) || targetEnvironment(macCatalyst)
                options.enableUserInteractionTracing = self.dataProvider.enableUserInteractionTracing
                options.enableUIViewControllerTracing = self.dataProvider.enableUIViewControllerTracking
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

        if shouldSendEvent == false {
            TracksLogDebug("📜 Events will not be sent because user has opted-out.")
        }

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

    /// Writes a JavaScript exception to the Crash Logging system, including its stack trace.
    /// Note that this function is provided mainly for hybrid sources like React Native.
    ///
    /// - Parameters:
    ///   - exception: The exception object
    ///   - callback: Callback triggered upon completion
    func logJavaScriptException(_ jsException: JSException, callback: @escaping () -> Void) {
        
        SentrySDK.capture(event: SentryEventJSException.init(jsException: jsException))
        
        DispatchQueue.global().async {
            SentrySDK.flush(timeout: self.flushTimeout)
            callback()
        }
    }
    
    /// Writes the error to the Crash Logging system, and includes a stack trace. This API supports for rich events.
    /// By setting a Tag/Value pair, you'll be able to filter these events, directly, with the `has:` operator (Sentry Web Interface).
    ///
    /// - Parameters:
    ///   - error: The error object
    ///   - tags: Tag Key/Value pairs to be set in the Error's Scope
    ///   - level: The level of severity to report in Sentry (`.error` by default)
    func logError(_ error: Error, tags: [String: String], level: SentryLevel = .error) {

        let event = Event.from(
            error: error as NSError,
            level: level
        )

        SentrySDK.capture(event: event) { scope in
            for (key, value) in tags {
                scope.setTag(value: value, key: key)
            }
        }

        dataProvider.didLogErrorCallback?(event)
    }

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
    func logErrorImmediately(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error, callback: @escaping () -> Void) {
        logErrorsImmediately([error], userInfo: userInfo, level: level, callback: callback)
    }

    func logErrorsImmediately(_ errors: [Error], userInfo: [String: Any]? = nil, level: SentryLevel = .error, callback: @escaping () -> Void) {
        logErrorsImmediately(errors, userInfo: userInfo, level: level, andWait: false, callback: callback)
    }

    /**
     Writes the error to the Crash Logging system, and includes a stack trace. This method will block the thread until the event is fired.

     - Parameters:
     - error: The error object
     - userInfo: A dictionary containing additional data about this error.
     - level: The level of severity to report in Sentry (`.error` by default)
     */
    func logErrorAndWait(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error) {
        logErrorsImmediately([error], userInfo: userInfo, level: level, andWait: true, callback: {})
        TracksLogDebug("💥 Events flush completed. When using Sentry, this either means all events were sent or that the flush timeout was reached.")
    }

    private func logErrorsImmediately(
        _ errors: [Error],
        userInfo: [String: Any]? = nil,
        level: SentryLevel = .error,
        andWait wait: Bool,
        callback: @escaping () -> Void
    ) {
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

        let flushEventThenCallCallback: () -> Void = {
            SentrySDK.flush(timeout: self.flushTimeout)
            callback()
        }
        if wait {
            flushEventThenCallCallback()
        } else {
            DispatchQueue.global().async { flushEventThenCallCallback() }
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
