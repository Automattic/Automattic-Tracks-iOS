import Foundation
import Sentry

/// A class that provides support for logging crashes. Not compatible with Objective-C.
public class CrashLogging {

    /// A singleton is maintained, but the host application needn't be aware of its existence.
    internal static let sharedInstance = CrashLogging()
    var dataProvider: CrashLoggingDataProvider?

    /// Thread-safe single initialization
    fileprivate static let threadSafeDispatchQueue = DispatchQueue(label: Bundle.main.bundleIdentifier ?? "tracks" + "-crash-logging-queue")
    fileprivate static var _isStarted = false
    internal static var isStarted: Bool {
        get {
            return threadSafeDispatchQueue.sync { _isStarted }
        }
        set {
            threadSafeDispatchQueue.sync { _isStarted = newValue }
        }
    }

    /// Internal Hooks (useful for tests and debugging)
    typealias CrashLoggingStartupCallback = (Bool) -> ()
    typealias BeforeSendCallback = (Event?, Bool) -> ()

    var crashLoggingStartupCallback: CrashLoggingStartupCallback?
    var beforeSendCallback: BeforeSendCallback?

    /**
     Initializes the crash logging system.

     - Parameters:
     - dataProvider: An object that will provide any required data to the crash logging system.

     - SeeAlso: CrashLoggingDataProvider
     */
    public static func start(withDataProvider dataProvider: CrashLoggingDataProvider) {

        // Only allow initializing this system once
        guard !isStarted else {
            return
        }

        isStarted = true

        // Store the data provider for future use
        sharedInstance.dataProvider = dataProvider

        // Create a Sentry client and start crash handler
        SentrySDK.start(options: [
            "dsn": dataProvider.sentryDSN,
            "debug": isDebugBuild,

            "maxBreadcrumbs": 500,

            "enableAutoSessionTracking": true,

            // Add additional data
            "release": dataProvider.releaseName,
            "environment": dataProvider.buildType,

            "integrations": enabledIntegrations
        ])

        SentrySDK.configureScope { scope in
            scope.setEnvironment(dataProvider.buildType)
        }

        /// Ugly hack to get this working – it can't be passed in `options` above
        SentrySDK.currentHub().getClient()?.options.beforeSend = sharedInstance.beforeSend


        // Refresh data from the data provider
        setNeedsDataRefresh()

        sharedInstance.crashLoggingStartupCallback?(SentrySDK.currentHub().getClient()!.options.enabled.boolValue)
    }

    func beforeSend(event: Event) -> Event? {
        /// Add the locale tag to allow grouping crashes by locale
        event.tags?["locale"] = NSLocale.current.languageCode

        #if DEBUG
        let shouldSendEvent = UserDefaults.standard.bool(forKey: "force-crash-logging") ?? false
        #else
        let shouldSendEvent = !CrashLogging.userHasOptedOut
        #endif

        beforeSendCallback?(event, shouldSendEvent)

        return shouldSendEvent ? event : nil
    }

    /// The current state of the user's choice to opt out of data collection. Provided by the data source.
    static var userHasOptedOut: Bool {
        guard let dataProvider = sharedInstance.dataProvider else {
            return true /// If we can't say for sure, assume the user has opted out
        }

        return dataProvider.userHasOptedOut
    }

    private static var isDebugBuild: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    private static var enabledIntegrations: [String] {
        return Sentry.Options.defaultIntegrations().filter {
            /// Disable Memory Warning Events – there are *lots* of them, and they're not particularly actionable
            $0 != "SentryUIKitMemoryWarningIntegration"
        }
    }

    /// Immediately crashes the application and generates a crash report.
    public static func crash() {
        SentrySDK.crash()
    }
}

// Manual Error Logging
public extension CrashLogging {

    /**
     Writes the error to the Crash Logging system, and includes a stack trace.

     - Parameters:
     - error: The error object
     - userInfo: A dictionary containing additional data about this error.
     - level: The level of severity to report in Sentry (`.error` by default)
    */
    static func logError(_ error: Error, userInfo: [String: Any]? = nil, level: SentryLevel = .error) {
        SentrySDK.capture(error: error) { scope in
            scope.setLevel(level)
            scope.setExtras(userInfo ?? (error as NSError).userInfo)
        }
    }

    /**
     Writes a message to the Crash Logging system, and includes a stack trace.
     - Parameters:
     - message: The message
     - properties: A dictionary containing additional information about this error
     - level: The level of severity to report in Sentry (`.info` by default)
    */
    static func logMessage(_ message: String, properties: [String: Any]? = nil, level: SentryLevel = .info) {
        SentrySDK.capture(message: message) { scope in
            scope.setLevel(level)
            scope.setExtras(properties)
        }
    }
}

// User Tracking
extension CrashLogging {

    var currentUser: Sentry.User {

        let anonymousUser = TracksUser(userID: nil, email: nil, username: nil).sentryUser

        /// Don't continue unless `start` has been called on the crash logger
        guard let dataProvider = self.dataProvider else {
            return anonymousUser
        }

        /// Don't continue if the data source doesn't yet have a user
        guard let user = dataProvider.currentUser else {
            return anonymousUser
        }

        let data = dataProvider.additionalUserData

        return user.sentryUser(withData: data)
    }

    /// Causes the Crash Logging System to refresh its knowledge about the current state of the system.
    ///
    /// This is required in situations like login / logout, when the system otherwise might not
    /// know a change has occured.
    ///
    /// Calling this method in these situations prevents
    public static func setNeedsDataRefresh() {
        SentrySDK.setUser(sharedInstance.currentUser)
    }
}
