import Foundation
#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

@objc public class ExPlat: NSObject, ABTesting {
    public static var shared: ExPlat!

    private let service: ExPlatService

    private let assignmentsKey = "ab-testing-assignments"
    private let ttlDateKey = "ab-testing-ttl-date"
    private let enrolledKey = "enrolled-experiments"

    private(set) var experimentNames: [String] = []

    private var ttl: TimeInterval {
        guard let ttlDate = UserDefaults.standard.object(forKey: ttlDateKey) as? Date else {
            return 0
        }

        return ttlDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
    }

    /// Check to see if ExPlat has stored the names of enrolled experiments
    ///
    public var enrolledArrayExists: Bool {
        UserDefaults.standard.object(forKey: enrolledKey) != nil
    }

    public init(configuration: ExPlatConfiguration,
                service: ExPlatService? = nil) {
        self.service = service ?? ExPlatService(configuration: configuration)
        super.init()
        register(experiments: ExPlat.shared?.experimentNames ?? [])
        subscribeToNotifications()
        ExPlat.shared = self
    }

    @objc public static func configure(platform: String,
                      oAuthToken: String?,
                      userAgent: String?,
                      anonId: String?) {
        _ = ExPlat(configuration: ExPlatConfiguration(platform: platform,
                                                       oAuthToken: oAuthToken,
                                                       userAgent: userAgent,
                                                       anonId: anonId))
    }

    /// Register the names of the experiments to be retrieved
    ///
    public func register(experiments experimentNames: [String]) {
        self.experimentNames = experimentNames
        service.experimentNames = experimentNames
    }

    deinit {
        unsubscribeFromNotifications()
    }

    /// Only refresh if the TTL has expired
    ///
    public func refreshIfNeeded(completion: (() -> Void)? = nil) {
        guard ttl <= 0 else {
            completion?()
            return
        }

        refresh(completion: completion)
    }

    /// Force the assignments to refresh
    ///
    public func refresh(completion: (() -> Void)? = nil) {
        service.getAssignments { [weak self] assignments in
            guard let `self` = self,
                  let assignments = assignments else {
                completion?()
                return
            }

            let validVariations = assignments.variations.filter { $0.value != nil }
            UserDefaults.standard.setValue(validVariations, forKey: self.assignmentsKey)

            var ttlDate = Date()
            ttlDate.addTimeInterval(TimeInterval(assignments.ttl))
            UserDefaults.standard.setValue(ttlDate, forKey: self.ttlDateKey)

            let enrolledExperimentNames = assignments.variations.map({ String($0.key) })
            UserDefaults.standard.setValue(enrolledExperimentNames, forKey: self.enrolledKey)

            completion?()
        }
    }

    public func experiment(_ name: String) -> Variation {
        guard let assignments = UserDefaults.standard.object(forKey: assignmentsKey) as? [String: String?],
              case let variation?? = assignments[name] else {
            return .control
        }

        switch variation {
        case "control":
            return .control
        case "treatment":
            return .treatment(nil)
        default:
            return .treatment(variation)
        }
    }

    /// Checks if the experiment name is contained in the enrolled experiments array
    /// returns false if there is no dictionary or the experiment is not registered
    ///
    public func isEnrolled(_ name: String) -> Bool {
        guard let enrolled = UserDefaults.standard.object(forKey: enrolledKey) as? [String] else {
            return false
        }
        
        return enrolled.contains(name)
    }

    /// Check if the app is entering background and/or foreground
    /// and start/stop the timers
    ///
    private func subscribeToNotifications() {
        let notificationCenter = NotificationCenter.default

        #if os(iOS) || os(watchOS) || os(tvOS)
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(macOS)
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSApplication.willBecomeActiveNotification, object: nil)
        #endif
    }

    private func unsubscribeFromNotifications() {
        let notificationCenter = NotificationCenter.default

        #if os(iOS) || os(watchOS) || os(tvOS)
        notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(macOS)
        notificationCenter.removeObserver(self, name: NSApplication.willBecomeActiveNotification, object: nil)
        #endif
    }

    /// When the app enter foreground refresh the assignments or
    /// start the timer
    ///
    @objc private func applicationWillEnterForeground() {
        refreshIfNeeded()
    }
}
