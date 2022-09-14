/// Defines whether to enable performance tracking, and if so, how to configure it.
public enum PerformanceTracking {

    public typealias Sampler = () -> Double

    case disabled
    case enabled(Configuration)

    /// Describe the configuration of the performance tracking functionality.
    ///
    /// – SeeAlso: The [Sentry docs](https://docs.sentry.io/platforms/apple/guides/ios/performance/instrumentation/automatic-instrumentation/#uiviewcontroller-tracking).
    public struct Configuration {
        /// This parameter allows clients to change the sample rate at runtime.
        ///
        /// - Important: The returned value must be between 0.0 (no events) and 1.0 (all events).
        public let sampler: Sampler
        /// Defaults to `true`.
        public let trackCoreData: Bool
        /// Defaults to `true`.
        public let trackFileIO: Bool
        /// Defaults to `true`.
        public let trackNetwork: Bool
        /// Defaults to `true`.
        ///
        /// – Note: This is only read in iOS, tvOS, and Mac Catalyst clients, i.e. those with UIKit.
        public let trackUserInteraction: Bool
        /// Defaults to `true`.
        ///
        /// - Note: As per the Sentry documentation, this only tracks first-party `UIViewController` subclasses. No SwiftUI views or third-party screens.
        /// – Note: This is only read in iOS, tvOS, and Mac Catalyst clients, i.e. those with UIKit.
        public let trackViewControllers: Bool

        // Compute the sample rate at runtime, to account for it accessing mutable state.
        // Clamp it between 0.0 and 1.0—the values Sentry uses.
        var sampleRate: Double { min(max(sampler(), 0.0), 1.0) }

        public init(
            sampler: @escaping Sampler = { 0.1 },
            trackCoreData: Bool = true,
            trackFileIO: Bool = true,
            trackNetwork: Bool = true,
            trackUserInteraction: Bool = true,
            trackViewControllers: Bool = true
        ) {
            self.sampler = sampler
            self.trackCoreData = trackCoreData
            self.trackFileIO = trackFileIO
            self.trackNetwork = trackNetwork
            self.trackUserInteraction = trackUserInteraction
            self.trackViewControllers = trackViewControllers
        }
    }
}
