import Foundation
import Sentry
import CocoaLumberjack

/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    /// We haven't fully evicted global state from all of Tracks yet, so we keep a global reference around for now
    struct Internals {
        static var crashLogging: CrashLogging?
    }

    private let dataProvider: CrashLoggingDataProvider
    private let eventLogging: EventLogging?

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
            options.debug = true

            options.environment = self.dataProvider.buildType
            options.releaseName = self.dataProvider.releaseName
            options.enableAutoSessionTracking = self.dataProvider.shouldEnableAutomaticSessionTracking

            options.beforeSend = self.beforeSend

            /// Attach stack traces to non-fatal errors
            options.attachStacktrace = true
        }

        Internals.crashLogging = self

        return self
    }

    public func shouldSendEvent() -> Bool {
        #if DEBUG
        return UserDefaults.standard.bool(forKey: "force-crash-logging")
        #else
        return !dataProvider.userHasOptedOut
        #endif
    }

    func beforeSend(event: Sentry.Event?) -> Sentry.Event? {

        DDLogDebug("📜 Firing `beforeSend`")

        #if DEBUG
        DDLogDebug("📜 This is a debug build")
        #endif

        /// If we shouldn't send the event we have nothing else to do here
        if !shouldSendEvent() {
            return nil
        }
        guard let event = event else {
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
            DDLogDebug("📜 Cancelling log file attachment – Event Logging is not initialized")
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
    func logErrorImmediately(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error, callback: @escaping (Result<Bool, Error>) -> Void) throws {
        try logErrorsImmediately([error], userInfo: userInfo, level: level, callback: callback)
    }

    func logErrorsImmediately(_ errors: [Error], userInfo: [String: Any]? = nil, level: SentryLevel = .error, callback: @escaping (Result<Bool, Error>) -> Void) throws {

        var serializer = SentryEventSerializer(dsn: dataProvider.sentryDSN)

        errors.forEach { error in
            let event = Event.from(
                error: error as NSError,
                level: level,
                user: dataProvider.currentUser?.sentryUser,
                extra: userInfo ?? (error as NSError).userInfo
            )

            serializer.add(event: addStackTrace(to: event))
        }

        guard let requestBody = try? serializer.serialize() else {
            DDLogError("⛔️ Unable to send errors to Sentry – error could not be serialized. Attempting to schedule delivery for another time.")
            errors.forEach {
                SentrySDK.capture(error: $0)
            }
            return
        }

        let dsn = try SentryDsn(string: dataProvider.sentryDSN)
        guard let authString = dsn.getAuthString() else {
            throw Errors.unableToConstructAuthStringError
        }

        var request = URLRequest(url: dsn.getEnvelopeEndpoint())
        request.httpMethod = "POST"
        request.httpBody = requestBody
        request.addValue(authString, forHTTPHeaderField: "X-Sentry-Auth")

        URLSession.shared.dataTask(with: request) { (responseData, urlResponse, error) in
            if let error = error {
                callback(.failure(error))
                return
            }

            let didSucceed = 200...299 ~= (urlResponse as! HTTPURLResponse).statusCode
            callback(.success(didSucceed))
        }.resume()
    }

    /**
     Writes the error to the Crash Logging system, and includes a stack trace. This method will block the thread until the event is fired.

     - Parameters:
     - error: The error object
     - userInfo: A dictionary containing additional data about this error.
     - level: The level of severity to report in Sentry (`.error` by default)
    */
    func logErrorAndWait(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error) throws {
        let semaphore = DispatchSemaphore(value: 0)

        var networkError: Error?

        try logErrorImmediately(error, userInfo: userInfo, level: level) { result in

            switch result {
                case .success:
                    DDLogDebug("💥 Successfully transmitted crash data")
                case .failure(let err):
                    networkError = err
            }

            semaphore.signal()
        }

        semaphore.wait()

        if let networkError = networkError {
            throw networkError
        }
    }

    /// A wrapper around the `SentryClient` shim – keeps each layer clean by avoiding optionality
    private func addStackTrace(to event: Event) -> Event {
        guard let client = SentrySDK.currentHub().getClient() else {
            return event
        }

        return client.addStackTrace(to: event, for: client)
    }
}

extension SentryDsn {
    func getAuthString() -> String? {

        guard let user = url.user else {
            return nil
        }

        var data = [
            "sentry_version=7",
            "sentry_client=tracks-manual-upload/\(TracksLibraryVersion)",
            "sentry_timesetamp=\(Date().timeIntervalSince1970)",
            "sentry_key=\(user)",
        ]

        if let password = url.password {
            data.append("sentry_secret=\(password)")
        }

        return "Sentry " + data.joined(separator: ",")
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

// MARK: - Helpers for hybrid SDKs
extension CrashLogging {
    /// Returns the options required to initialize Sentry in other platforms.
    public func getOptionsDict() -> [String: Any] {
        return [
            "dsn": self.dataProvider.sentryDSN,
            "environment": self.dataProvider.buildType,
            "releaseName": self.dataProvider.releaseName
        ]
    }

    /// Return the current Sentry user.
    /// This helper allows events triggered by other platforms to include the current user.
    public func getSentryUserDict() -> [String: Any]? {
        return dataProvider.currentUser?.sentryUser.serialize()
    }

    /// Attachs the current scope to an event and returns it.
    /// This helper allows events triggered by other platforms to include the same scope as if they would be triggered in this platform.
    ///
    /// - Parameters:
    ///   - eventDict: The event object
    public func attachScopeToEvent(_ eventDict: [String: Any]) -> [String: Any] {
        let scope = SentrySDK.currentHub().getScope().serialize()

        // Setup tags
        var tags = scope["tags"] as? [String: String] ?? [String: String]()
        tags["locale"] = NSLocale.current.languageCode

        /// Always provide a value in order to determine how often we're unable to retrieve application state
        tags["app.state"] = ApplicationFacade().applicationState ?? "unknown"

        tags["release"] = self.dataProvider.releaseName

        // Assign scope to event
        var eventWithScope = eventDict
        eventWithScope["tags"] = tags
        eventWithScope["breadcrumbs"] = scope["breadcrumbs"]
        eventWithScope["contexts"] = scope["context"]

        return eventWithScope
    }

    /// Writes the envelope to the Crash Logging system, the envelope contains all the data required for data ingestion in Sentry.
    /// This function is based on the original Sentry implementation for React native: https://github.com/getsentry/sentry-react-native/blob/aa4eb11415cbb73bbd0033e4f0926b539d22315b/ios/RNSentry.m#L118-L158
    ///
    /// - Parameters:
    ///   - envelopeDict: The envelope object.
    public func logEnvelope(_ envelopeDict: [String: Any]) {
        if JSONSerialization.isValidJSONObject(envelopeDict) {
            guard let headerDict = envelopeDict["header"] as? [String: Any] else {
                DDLogError("⛔️ Unable to send envelope to Sentry – header is not defined in the envelope.")
                return
            }
            guard let headerEventId = headerDict["event_id"] as? String else {
                DDLogError("⛔️ Unable to send envelope to Sentry – event id is not defined in the envelope header.")
                return
            }
            guard let payloadDict = envelopeDict["payload"] as? [String: Any] else {
                DDLogError("⛔️ Unable to send envelope to Sentry – payload is not defined in the envelope.")
                return
            }
            guard let eventLevel = payloadDict["level"] as? String else {
                DDLogError("⛔️ Unable to send envelope to Sentry – level is not defined in the envelope payload.")
                return
            }

            // Define the envelope header
            let sdkInfo = SentrySdkInfo.init(dict: headerDict)
            let eventId = SentryId.init(uuidString: headerEventId)
            let envelopeHeader = SentryEnvelopeHeader.init(id: eventId, andSdkInfo: sdkInfo)

            guard let envelopeItemData = try? JSONSerialization.data(withJSONObject: payloadDict) else {
                DDLogError("⛔️ Unable to send envelope to Sentry – payload could not be serialized.")
                return
            }

            let itemType = payloadDict["type"] as? String ?? "event"
            let envelopeItemHeader = SentryEnvelopeItemHeader.init(type: itemType, length: UInt(bitPattern: envelopeItemData.count))
            let envelopeItem = SentryEnvelopeItem.init(header: envelopeItemHeader, data: envelopeItemData)
            let envelope = SentryEnvelope.init(header: envelopeHeader, singleItem: envelopeItem)

            #if DEBUG
            SentrySDK.currentHub().getClient()?.capture(envelope: envelope)
            #else
            if eventLevel == "fatal" {
                // Storing to disk happens asynchronously with captureEnvelope
                SentrySDK.currentHub().getClient()?.store(envelope)
            } else {
                SentrySDK.currentHub().getClient()?.capture(envelope: envelope)
            }
            #endif
        } else {
            DDLogError("⛔️ Unable to send envelope to Sentry – envelope is not a valid JSON object.")
        }
    }
}

// MARK: - Event Logging
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
