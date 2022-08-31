/// Defines whether to enable performance tracking, and if so, how to configure it.
public enum PerformanceTracking {

    case disabled
    case enabled(Configuration)

    /// Describe the configuration of the performance tracking functionality.
    ///
    /// – SeeAlso: The [Sentry docs](https://docs.sentry.io/platforms/apple/guides/ios/performance/instrumentation/automatic-instrumentation/#uiviewcontroller-tracking).
    public struct Configuration {
        /// - Important: Must be between 0.0 (no events) and 1.0 (all events).
        public let sampleRate: Double
        /// Defaults to `true`.
        public let trackCoreData: Bool
        /// Defaults to `true`.
        public let trackFileIO: Bool
        /// Defaults to `true`.
        public let trackNetwork: Bool
        /// Defaults to `true`.
        public let trackUserInteraction: Bool
        /// Defaults to `true`.
        /// - Note: As per the Sentry documentation, this only tracks first-party `UIViewController` subclasses. No SwiftUI views or third-party screens.
        public let trackViewControllers: Bool

        public init(
            sampleRate: Double,
            trackCoreData: Bool = true,
            trackFileIO: Bool = true,
            trackNetwork: Bool = true,
            trackUserInteraction: Bool = true,
            trackViewControllers: Bool = true
        ) {
            // Force sample rate to be between 0.0 and 1.0.
            self.sampleRate = min(max(0.0, sampleRate), 1.0)
            self.trackCoreData = trackCoreData
            self.trackFileIO = trackFileIO
            self.trackNetwork = trackNetwork
            self.trackUserInteraction = trackUserInteraction
            self.trackViewControllers = trackViewControllers
        }
    }
}
