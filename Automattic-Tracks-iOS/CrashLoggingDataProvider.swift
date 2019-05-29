import Foundation

public protocol CrashLoggingDataProvider {
    var sentryDSN: String { get }
    var userHasOptedOut: Bool { get }
    var buildType: String { get }
    var releaseName: String { get }
    var currentUser: TracksUser? { get }
    var additionalUserData: [String : Any] { get }
}
   
/// Default implementations of common protocol properties
public extension CrashLoggingDataProvider {

    var releaseName: String {
        return Bundle.main.object(forInfoDictionaryKey: kCFBundleVersionKey as String) as! String
    }

    var additionalUserData: [String : Any] {
        return [ : ]
    }
}
