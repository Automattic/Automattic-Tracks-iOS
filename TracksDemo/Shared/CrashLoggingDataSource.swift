import AutomatticTracks

struct CrashLoggingDataSource: CrashLoggingDataProvider {
    var sentryDSN: String = Secrets.sentryDsn

    var userHasOptedOut: Bool = false

    var buildType: String = "test"

    var currentUser: TracksUser? {
        Settings().tracksUser
    }

    var shouldEnableAutomaticSessionTracking = true
}

@objc(CrashLogging)
/// A shim for intializing `CrashLogging` from Objective-C
public class CrashLoggingInitializer: NSObject {

    private let crashLogging = try! CrashLogging(dataProvider: CrashLoggingDataSource()).start()

    @objc
    func start() throws {
        UserDefaults.standard.setValue(true, forKey: "force-crash-logging")
        crashLogging.setNeedsDataRefresh()
    }
}
