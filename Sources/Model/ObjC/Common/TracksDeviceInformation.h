#import <Foundation/Foundation.h>
#import <CoreGraphics/CoreGraphics.h>

NS_ASSUME_NONNULL_BEGIN

@interface TracksDeviceInformation : NSObject

@property (nonatomic, readonly) NSString *os;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *manufacturer;
@property (nonatomic, readonly) NSString *brand;
@property (nullable, nonatomic, readonly) NSString *model;

@property (nullable, nonatomic, readonly) NSString *appName;
@property (nullable, nonatomic, readonly) NSString *appVersion;
@property (nullable, nonatomic, readonly) NSString *appBuild;
@property (nonatomic, readonly) NSString *appBuildConfiguration;

// This information has the tendency to change
@property (nonatomic, readonly) NSString *deviceLanguage;
@property (nullable, nonatomic, readonly) NSString *currentNetworkOperator;
@property (nullable, nonatomic, readonly) NSString *currentNetworkRadioType;
@property (nonatomic, assign) BOOL isWiFiConnected;

/// Preferred reading content size based on the accessibility setting of the iOS device.
/// - This will be null for Mac OS.
///
@property (nullable, nonatomic, readonly) NSString *preferredContentSizeCategory;

/// Returns `true` if the preferred reading content size falls under accessibility category.
///
/// - Uses `UIContentSizeCategoryIsAccessibilityCategory` method.
/// - This will be `false` for Mac OS.
///
@property (nonatomic, readonly) BOOL isAccessibilityCategory;

/**
 * Indicates whether the device has an Internet connection.
 */
@property (nonatomic, assign) BOOL isOnline;
@property (nonatomic, assign) BOOL isAppleWatchConnected;
@property (nonatomic, assign) BOOL isVoiceOverEnabled;
@property (nonatomic, assign) CGFloat statusBarHeight;
@property (nonatomic, readonly) NSString *orientation;

@end

NS_ASSUME_NONNULL_END
