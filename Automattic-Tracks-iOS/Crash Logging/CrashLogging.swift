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

    init(dataProvider: CrashLoggingDataProvider, eventLogging: EventLogging? = nil) {
        self.dataProvider = dataProvider
        self.eventLogging = eventLogging
    }

    public func start() {
        SentrySDK.start { options in
            options.dsn = self.dataProvider.sentryDSN
            options.debug = true // Helpful to see what's going on

            options.environment = self.dataProvider.buildType
            options.releaseName = self.dataProvider.releaseName

            options.beforeSend = self.beforeSend
        }

        CrashLoggingInternals.crashLogging = self
    }

    private func beforeSend(event: Sentry.Event?) -> Sentry.Event? {
        guard let event = event else {
            return nil
        }

        DDLogDebug("📜 Firing `beforeSend`")

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

    /// Sends an `Event` to Sentry and triggers a callback on completion
    func logErrorImmediately(_ error: Error, level: SentryLevel = .error, callback: @escaping (Result<Bool, Error>) -> Void) throws {
        try logErrorsImmediately([error], level: level, callback: callback)
    }

    func logErrorsImmediately(_ errors: [Error], level: SentryLevel = .error, callback: @escaping (Result<Bool, Error>) -> Void) throws {

        var serializer = SentryEventSerializer(dsn: dataProvider.sentryDSN)

        errors.forEach {
            let event = Event(level: level)
            event.message = SentryMessage(formatted: $0.localizedDescription)
            event.timestamp = Date()
            serializer.add(event: event)
        }


        guard let requestBody = try? serializer.serialize() else {
            DDLogError("⛔️ Unable to send errors to Sentry – error could not be serialized. Attempting to schedule delivery for another time.")
            errors.forEach {
                SentrySDK.capture(error: $0)
            }
            return
        }

        let endpoint = try SentryDsn(string: dataProvider.sentryDSN).getEnvelopeEndpoint()
        var request = URLRequest(url: endpoint)
        request.httpMethod = "POST"
        request.httpBody = requestBody

        URLSession.shared.dataTask(with: request) { (responseData, urlResponse, error) in
            if let error = error {
                callback(.failure(error))
                return
            }

            let didSucceed = 200...299 ~= (urlResponse as! HTTPURLResponse).statusCode
            callback(.success(didSucceed))
        }.resume()
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
