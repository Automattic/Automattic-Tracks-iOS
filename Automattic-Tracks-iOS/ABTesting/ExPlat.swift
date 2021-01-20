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

    private var ttl: TimeInterval {
        guard let ttlDate = UserDefaults.standard.object(forKey: ttlDateKey) as? Date else {
            return 0
        }

        return ttlDate.timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
    }

    private(set) var scheduledTimer: Timer?

    public init(configuration: ExPlatConfiguration,
         service: ExPlatService? = nil) {
        self.service = service ?? ExPlatService(configuration: configuration)
        super.init()
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

    deinit {
        unsubscribeFromNotifications()
    }

    /// Only refresh if the TTL has expired
    ///
    public func refreshIfNeeded(completion: (() -> Void)? = nil) {
        guard ttl > 0 else {
            completion?()
            scheduleRefresh()
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
            self.scheduleRefresh()

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

    private func scheduleRefresh() {
        if ttl > 0 {
            scheduledTimer?.invalidate()

            /// Schedule the refresh on a background thread
            DispatchQueue.global(qos: .background).async { [weak self] in
                guard let `self` = self else {
                    return
                }

                self.scheduledTimer = Timer.scheduledTimer(withTimeInterval: self.ttl, repeats: true) { [weak self] timer in
                    self?.refresh()
                    timer.invalidate()
                }

                RunLoop.current.run()
            }


        } else {
            refresh()
        }
    }

    /// Check if the app is entering background and/or foreground
    /// and start/stop the timers
    ///
    private func subscribeToNotifications() {
        let notificationCenter = NotificationCenter.default

        #if os(iOS) || os(watchOS) || os(tvOS)
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(macOS)
        notificationCenter.addObserver(self, selector: #selector(applicationDidEnterBackground), name: NSApplication.didResignActiveNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(applicationWillEnterForeground), name: NSApplication.willBecomeActiveNotification, object: nil)
        #endif
    }

    private func unsubscribeFromNotifications() {
        let notificationCenter = NotificationCenter.default

        #if os(iOS) || os(watchOS) || os(tvOS)
        notificationCenter.removeObserver(self, name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        #elseif os(macOS)
        notificationCenter.removeObserver(self, name: NSApplication.didResignActiveNotification, object: nil)
        notificationCenter.removeObserver(self, name: NSApplication.willBecomeActiveNotification, object: nil)
        #endif
    }

    /// When the app goes to background stop the timer
    ///
    @objc private func applicationDidEnterBackground() {
        scheduledTimer?.invalidate()
    }

    /// When the app enter foreground refresh the assignments or
    /// start the timer
    ///
    @objc private func applicationWillEnterForeground() {
        refreshIfNeeded()
    }
}
