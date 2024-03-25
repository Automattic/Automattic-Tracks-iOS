import Foundation

#if SWIFT_PACKAGE
import AutomatticTracksModel
#endif

public protocol CrashLoggingDataProvider {
    var sentryDSN: String { get }
    var userHasOptedOut: Bool { get }
    var buildType: String { get }
    var releaseName: ReleaseName { get }
    var currentUser: TracksUser? { get }
    var additionalUserData: [String: Any] { get }
    var errorEventsSamplingRate: Double { get }
    var shouldEnableAutomaticSessionTracking: Bool { get }
    var performanceTracking: PerformanceTracking { get }
    /// Whether app hang are captured.
    var enableAppHangTracking: Bool { get }
    /// Whether HTTP client errors are captured.
    var enableCaptureFailedRequests: Bool { get }
}

public enum ReleaseName {
    /**
     Sets the release name attached for every event sent to Sentry. It's intended to use in debug.
     - Parameter name: The name of the release.
     */
    case setByApplication(name: String)
    
    /**
     Delegates setting the release name to the Tracks library. It's intended to use in release
     builds. The crash logging framework will single-handedly set the release name based on the
     build configuration.
     */
    case setByTracksLibrary
}

/// Default implementations of common protocol properties
public extension CrashLoggingDataProvider {

    var releaseName: ReleaseName {
        return ReleaseName.setByTracksLibrary
    }

    var additionalUserData: [String: Any] {
        return [ : ]
    }

    var shouldEnableAutomaticSessionTracking: Bool {
        return false
    }

    /// Performance tracking is disabled by default to avoid accidentally logging what could be a significant number of extra events
    /// and blow up our events budget.
    var performanceTracking: PerformanceTracking { .disabled }

    var enableAutoPerformanceTracking: Bool {
        switch performanceTracking {
        case .enabled: return true
        case .disabled: return false
        }
    }

    var tracesSampler: PerformanceTracking.Sampler {
        guard case .enabled(let config) = performanceTracking else { return { 0.0 } }
        return config.sampler
    }

    var tracesSampleRate: Double {
        guard case .enabled(let config) = performanceTracking else { return 0.0 }
        return config.sampleRate
    }

    var profilingRate: Double {
        guard case .enabled(let config) = performanceTracking else { return 0.0 }
        return config.profilingRate
    }

    var enableUIViewControllerTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackViewControllers
    }

    var enableNetworkTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackNetwork
    }

    var enableFileIOTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackFileIO
    }

    var enableCoreDataTracking: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackCoreData
    }

    var enableUserInteractionTracing: Bool {
        guard case .enabled(let config) = performanceTracking else { return false }
        return config.trackUserInteraction
    }

    /// App hang tracking is disabled by default to avoid unexpected events being tracked.
    var enableAppHangTracking: Bool {
        return false
    }

    /// HTTP client errors are disabled by default to avoid unexpected events being tracked.
    var enableCaptureFailedRequests: Bool {
        return false
    }

    var errorEventsSamplingRate: Double {
        return 1.0
    }
}
