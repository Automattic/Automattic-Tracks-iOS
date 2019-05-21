import Foundation
import Sentry

/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    /// A singleton is maintained, but the host application needn't be aware of its existence.
    private static let sharedInstance = CrashLogging()

    fileprivate var dataProvider: CrashLoggingDataProvider! {
        didSet{
            applyUserTrackingPreferences()
        }
    }

    /**
     Initializes the crash logging system.

     - Parameters:
     - dataProvider: An object that will provide any required data to the crash logging system.

     - SeeAlso: CrashLoggingDataProvider
     */
    public static func start(withDataProvider dataProvider: CrashLoggingDataProvider) {
        // Create a Sentry client and start crash handler
        do {
            Client.shared = try Client(dsn: dataProvider.sentryDSN)

            // Store lots of breadcrumbs to trace errors
            Client.shared?.breadcrumbs.maxBreadcrumbs = 500

            // Automatically track screen transitions
            Client.shared?.enableAutomaticBreadcrumbTracking()

            // Automatically track low-memory events
            Client.shared?.trackMemoryPressureAsEvent()

            try Client.shared?.startCrashHandler()

            // Override event serialization to append the logs, if needed
            Client.shared?.beforeSerializeEvent = sharedInstance.beforeSerializeEvent
            Client.shared?.shouldSendEvent = sharedInstance.shouldSendEvent

            // Apply Sentry Tags
            Client.shared?.releaseName = dataProvider.releaseName
            Client.shared?.environment = dataProvider.buildType

            // Store the data provider for future use
            sharedInstance.dataProvider = dataProvider

        } catch let error {
            logError(error)
        }
    }

    /// A Sentry hook used to attach any additional data to the event.
    private func beforeSerializeEvent(_ event: Event) {
        event.tags?["locale"] = NSLocale.current.languageCode
    }

    /// A Sentry hook that controls whether or not the event should be sent.
    private func shouldSendEvent(_ event: Event?) -> Bool {
        #if DEBUG
        return false
        #else
        return !CrashLogging.userHasOptedOut
        #endif
    }

    /// The current state of the user's choice to opt out of data collection. Provided by the data source.
    public static var userHasOptedOut: Bool {
        get {
            /// If we can't say for sure, assume the user has opted out
            guard sharedInstance.dataProvider != nil else { return true }
            return sharedInstance.dataProvider.userHasOptedOut
        }
        set {
            sharedInstance.applyUserTrackingPreferences()
        }
    }

    /// Immediately crashes the application and generates a crash report.
    public static func crash() {
        Client.shared?.crash()
    }
}

// Manual Error Logging
public extension CrashLogging {

    /**
     Writes the error to the Crash Logging system, and includes a stack trace.

     - Parameters:
     - error: The error object
     - level: The level of severity to report in Sentry (`.error` by default)
     - userInfo: A dictionary containing additional data about this error
    */
    static func logError(_ error: Error, userInfo: [String : Any]? = nil, level: SentrySeverity = .error) {
        let event = Event(level: .error)
        event.message = error.localizedDescription
        event.extra = userInfo

        Client.shared?.appendStacktrace(to: event)
        Client.shared?.send(event: event)
    }

    /**
     Writes a message to the Crash Logging system, and includes a stack trace.
     - Parameters:
     - message: The message
     - level: The level of severity to report in Sentry (`.error` by default)
     - userInfo: A dictionary containing additional data about this error
    */
    static func logMessage(_ message: String, userInfo: [String : Any]? = nil, level: SentrySeverity = .info) {
        let event = Event(level: level)
        event.message = message
        event.extra = userInfo

        Client.shared?.appendStacktrace(to: event)
        Client.shared?.send(event: event)
    }
}

// User Tracking
extension CrashLogging {

    func applyUserTrackingPreferences() {

        if !CrashLogging.userHasOptedOut {
            enableUserTracking()
        }
        else {
            disableUserTracking()
        }
    }

    func enableUserTracking() {
        /// Don't continue unless `start` has been called on the crash logger
        guard self.dataProvider != nil else { return }

        Client.shared?.user = Sentry.User(user: dataProvider.currentUser, additionalUserData: dataProvider.additionalUserData)
    }

    func disableUserTracking() {
        Client.shared?.clearContext()
    }
}
