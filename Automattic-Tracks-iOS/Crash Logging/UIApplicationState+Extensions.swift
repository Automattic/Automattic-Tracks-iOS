
import Foundation
import UIKit

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
