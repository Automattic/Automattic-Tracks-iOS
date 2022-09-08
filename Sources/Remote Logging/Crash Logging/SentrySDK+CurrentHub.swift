import Sentry

@objc
protocol SentrySDKInternalMethods {
    @objc
    var currentHub: SentryHub { get }
}

/// This is an extension on `SentrySDK` to hides the access to the `currentHub()` methods we use in
/// the codebase.
///
/// The reason for this, other than to implement the good old Law of Demeter, is that `currentHub()`
/// is no longer available in version 7.x. In the future we hope to be able to access this
/// information anyway, either by Sentry helping us and introducing an alternative way to do what
/// we need or by us doing some clever private API access. Therefore, we don't want to wholesale
/// delete the code that used to work in version 6.x, but rather bypass it for the time being.
extension SentrySDK {

    /// Returns the `Client` for the current `SentryHub`.
    ///
    /// - Note: Once we'll migrate to version 7.x, this will return `.none` because `currentHub`
    /// will no longer be available.
    static func currentClient() -> Sentry.Client? {
        _currentHub()?.getClient()
    }

    /// Returns the current `SentryHub`.
    ///
    /// - Note: Once we'll migrate to version 7.x, this will return `.none` because `currentHub`
    /// will no longer be available.
    private static func _currentHub() -> SentryHub? {
        let currentHubSelector = #selector(getter: SentrySDKInternalMethods.currentHub)

        guard SentrySDK.responds(to: currentHubSelector) else {
            return nil
        }

        return SentrySDK.perform(currentHubSelector).takeUnretainedValue() as? SentryHub
    }
}
