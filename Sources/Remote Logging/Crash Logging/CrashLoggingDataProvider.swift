import Foundation

#if SWIFT_PACKAGE
import AutomatticTracksModel
#endif

public protocol CrashLoggingDataProvider {
    var sentryDSN: String { get }
    var userHasOptedOut: Bool { get }
    var buildType: String { get }
    var releaseName: String { get }
    var currentUser: TracksUser? { get }
    var additionalUserData: [String: Any] { get }
    var shouldEnableAutomaticSessionTracking: Bool { get }
    var performanceTracking: PerformanceTracking { get }
}

/// Default implementations of common protocol properties
public extension CrashLoggingDataProvider {

    var releaseName: String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }

    var additionalUserData: [String: Any] {
        return [ : ]
    }

    var shouldEnableAutomaticSessionTracking: Bool {
        return false
    }

    /// Performance tracking is disabled by default to avoid accidentally logging what could be a significant number of extra events
    /// and blow up our budget monitoring.
    var performanceTracking: PerformanceTracking { .disabled }

    var enableAutoPerformanceTracking: Bool {
        switch performanceTracking {
        case .enabled: return true
        case .disabled: return false
        }
    }

    var tracesSampleRate: Double {
        guard case .enabled(let config) = performanceTracking else { return 0.0 }
        return config.sampleRate
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
}
