import AutomatticTracks

struct CrashLoggingDataSource: CrashLoggingDataProvider {
    var sentryDSN: String = Secrets.sentryDsn

    var userHasOptedOut: Bool = false

    var buildType: String = "test"

    var currentUser: TracksUser? {
        Secrets.tracksUser
    }

    var shouldEnableAutomaticSessionTracking = true

    // This is a demo app, we can afford to sample all events. However, Sentry recomends a lower
    // sample rate in production.
    var performanceTracking: PerformanceTracking = .enabled(.init(sampler: { 1.0 }))
}
