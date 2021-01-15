import AutomatticTracks

struct CrashLoggingDataSource: CrashLoggingDataProvider {
    var sentryDSN: String = Secrets.sentryDsn

    var userHasOptedOut: Bool = false

    var buildType: String = "test"

    var currentUser: TracksUser? {
        Secrets.tracksUser
    }

    var shouldEnableAutomaticSessionTracking = true
        Settings().tracksUser
    }
}

@objc
/// A shim for intializing `CrashLogging` from Objective-C
public class CrashLoggingInitializer: NSObject {
    @objc
    static func start() {
        CrashLogging.start(withDataProvider: CrashLoggingDataSource(), eventLogging: nil)
        UserDefaults.standard.setValue(true, forKey: "force-crash-logging")
        CrashLogging.setNeedsDataRefresh()
    }
}
