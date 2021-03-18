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

    public init(configuration: ExPlatConfiguration,
         service: ExPlatService? = nil) {
        self.service = service ?? ExPlatService(configuration: configuration)
        super.init()
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

    /// Only refresh if the TTL has expired
    ///
    public func refreshIfNeeded(completion: (() -> Void)? = nil) {
        guard ttl > 0 else {
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
}
