@import Foundation;


#if TARGET_OS_IPHONE
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIApplication (SharedIfAvailable)

/// Returns the shared UIApplication if not running in an app extension;
+ (nullable UIApplication *)sharedIfAvailable;

@end

NS_ASSUME_NONNULL_END

#endif
