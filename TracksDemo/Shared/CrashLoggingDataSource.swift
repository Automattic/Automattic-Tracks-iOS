import Foundation
import AutomatticTracks

struct CrashLoggingDataSource: CrashLoggingDataProvider {
    var sentryDSN: String = Secrets.sentryDsn

    var userHasOptedOut: Bool = false

    var buildType: String = "test"

    var currentUser: TracksUser? {
        Secrets.tracksUser
    }

    var shouldEnableAutomaticSessionTracking = true
}
