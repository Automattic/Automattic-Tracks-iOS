
import Foundation

#if os(iOS)
import UIKit
#endif

/// An interface that provides information from UIApplication or NSApplication.
///
/// Though in reality, this is only currently useful for iOS. XD
///
final class ApplicationFacade {
    /// The current state of the application (e.g. background, active, or inactive). This is
    /// generally used only for `Event` tags.
    ///
    /// - Returns: The string-representation of the state or `nil` if the current platform is
    ///            not supported.
    ///
    var applicationState: String? {
        #if os(iOS)
        guard Thread.isMainThread else {
            // UIApplication.applicationState can only be accessed from the main thread.
            return "unavailable"
        }

        return UIApplication.shared.applicationState.descriptionForEventTag

        #else

        return nil

        #endif
    }
}

// MARK: - iOS Only

#if os(iOS)

extension UIApplication.State {

    /// A string representation of `UIApplication.State` to be used as a value for `Event.tags`.
    ///
    var descriptionForEventTag: String {
        switch self {
        case .active:
            return "active"
        case .background:
            return "background"
        case .inactive:
            return "inactive"
        @unknown default:
            return "unknown"
        }
    }
}

#endif
