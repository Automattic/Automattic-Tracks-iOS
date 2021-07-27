
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
    /// not supported.
    ///
    var applicationState: String? {
        #if os(iOS)
        guard Thread.isMainThread else {
            // UIApplication.applicationState can only be accessed from the main thread.
            return "unavailable"
        }

        if let app = UIApplication.sharedIfAvailable {
            return app.applicationState.descriptionForEventTag
        }
        else {
            return "unavailable"
        }


        #else

        return nil

        #endif
    }
}

// MARK: - iOS Only

#if os(iOS)

private extension UIApplication {
    // When compiling with Swift Package Manager, it wants us to
    // use only extension-safe API. We still want to use UIApplication
    // when it's available, while not using extension-unsafe API
    // when not available. So we're going to be sneaky about getting
    // `UIApplication.shared`, but only when it should already be safe.
    static var sharedIfAvailable: UIApplication? {

        guard Bundle.main.bundleURL.pathExtension != "appex"
        else { return nil }

        let sharedAppSelector = Selector(("sharedApplication"))
        if let appClass = NSClassFromString("UIApplication"),
           let performableClass = (appClass as Any) as? NSObjectProtocol,
           performableClass.responds(to: sharedAppSelector),
           let performResult = performableClass.perform(sharedAppSelector),
           let app = performResult.takeUnretainedValue() as? UIApplication {

            return app
        }
        return nil
    }
}


private extension UIApplication.State {

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
