#import "TracksDeviceInformation.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
@import UIDeviceIdentifier;
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "WatchSessionManager.h"
#import "UIApplication+Extensions.h"
#else
#import <Foundation/Foundation.h>
#import <AppKit/AppKit.h>
#import <SystemConfiguration/SystemConfiguration.h>
#include <sys/types.h>
#include <sys/sysctl.h>
#endif

@interface TracksDeviceInformation ()

@property (nonatomic, assign) BOOL isReachable;
@property (nonatomic, assign) BOOL isReachableByWiFi;
@property (nonatomic, assign) BOOL isReachableByWWAN;

#if TARGET_OS_SIMULATOR
@property (nonatomic, assign) UIDeviceOrientation lastKnownDeviceOrientation;
@property (nonatomic, strong) NSString *lastKnownPreferredContentSizeCategory;
#endif

@end

@implementation TracksDeviceInformation

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self preloadDeviceProperties];
    }

    return self;
}

- (void)preloadDeviceProperties
{
#if TARGET_OS_IPHONE
    void (^preload)(void) = ^(void) {
        self.lastKnownDeviceOrientation = UIDevice.currentDevice.orientation;
        self.lastKnownPreferredContentSizeCategory = UIApplication.sharedIfAvailable.preferredContentSizeCategory;
    };

    if ([NSThread isMainThread]) {
        preload();
        return;
    }

    dispatch_async(dispatch_get_main_queue(), preload);
#endif
}

- (NSString *)brand
{
    return @"Apple";
}

- (NSString *)manufacturer
{
    return @"Apple";
}

- (NSString *)currentNetworkOperator
{
#if TARGET_OS_SIMULATOR
    return @"Carrier (Simulator)";
#elif TARGET_OS_IPHONE
    CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];

    NSString *carrierName = nil;
    if (carrier) {
        carrierName = [NSString stringWithFormat:@"%@ [%@/%@/%@]", carrier.carrierName, [carrier.isoCountryCode uppercaseString], carrier.mobileCountryCode, carrier.mobileNetworkCode];
    }

    return carrierName;
#else
    return @"Not Applicable";
#endif
}


- (NSString *)currentNetworkRadioType
{
#if TARGET_OS_SIMULATOR
    return @"None (Simulator)";
#elif TARGET_OS_IPHONE
    CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
    NSString *type = nil;
    if ([netInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
        type = [netInfo currentRadioAccessTechnology];
    }

    return type;
#else   // Mac
    return @"Unknown";
#endif
}


- (NSString *)deviceLanguage
{
    return [[NSLocale currentLocale] localeIdentifier];
}

- (NSString *)model
{
#if TARGET_OS_IPHONE
    return [UIDeviceHardware platformString];
#else   // Mac
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.model", model, &size, NULL, 0);
    NSString *modelString = [NSString stringWithUTF8String:model];
    free(model);

    return modelString;
#endif
}


- (NSString *)os
{
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] systemName];
#else   // Mac
    return @"OS X";
#endif
}

- (NSString *)version
{
#if TARGET_OS_IPHONE
    return [[UIDevice currentDevice] systemVersion];
#else   // Mac
    NSOperatingSystemVersion version = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger major = version.majorVersion;
    NSInteger minor = version.minorVersion;
    NSInteger patch = version.patchVersion;
    return [NSString stringWithFormat: @"%ld.%ld.%ld", (long)major, (long)minor, (long)patch];
#endif
}

-(BOOL)isAppleWatchConnected{
#if TARGET_OS_IPHONE
    return [[WatchSessionManager shared] hasBeenPreviouslyPaired];
#else   // Mac
    return NO;
#endif
}

-(BOOL)isVoiceOverEnabled{

#if TARGET_OS_IPHONE
    return UIAccessibilityIsVoiceOverRunning();
#else   // Mac
    Boolean exists = false;
    BOOL result = CFPreferencesGetAppBooleanValue(CFSTR("voiceOverOnOffKey"), CFSTR("com.apple.universalaccess"), &exists);

    if(exists){
        return result;
    }

    return NO;
#endif
}

-(NSString *)orientation{
#if TARGET_OS_IPHONE
     UIDeviceOrientation orientation = [self deviceOrientation];

     if (orientation == UIDeviceOrientationPortrait || orientation == UIDeviceOrientationPortraitUpsideDown) {
         return @"Portrait";
     } else if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
         return @"Landscape";
     } else {
         return @"Unknown";
     }
#else   // Mac
    return @"Unknown";
#endif
}

#pragma mark - Calls that need to run on the main thread

#if TARGET_OS_IPHONE
// This method was created because UIDevice.currentDevice.orientation should only
// be called from the main thread.
//
- (UIDeviceOrientation)deviceOrientation {
    if ([NSThread isMainThread]) {
        self.lastKnownDeviceOrientation = UIDevice.currentDevice.orientation;
    }

    return self.lastKnownDeviceOrientation;
}
#endif

/// Preferred reading content size based on the accessibility setting of the iOS device.
/// 
/// - This will be NULL for Mac OS.
///
- (NSString *)preferredContentSizeCategory {
#if TARGET_OS_IPHONE
    if ([NSThread isMainThread]) {
        self.lastKnownPreferredContentSizeCategory = UIApplication.sharedIfAvailable.preferredContentSizeCategory;
    }

    return self.lastKnownPreferredContentSizeCategory;
#else   // Mac
    return NULL;
#endif
}

/// Returns `true` if the preferred reading content size falls under accessibility category.
///
/// - Uses `UIContentSizeCategoryIsAccessibilityCategory` method.
/// - This will be `false` for Mac OS.
///
- (BOOL)isAccessibilityCategory {
#if TARGET_OS_IPHONE
    NSString *preferredCategory = [self preferredContentSizeCategory];
    if (preferredCategory == nil) {
        return NO;
    }

    return UIContentSizeCategoryIsAccessibilityCategory(preferredCategory);

#else   // Mac
    return NO;
#endif
}

#pragma mark - App Specific Information

- (NSString *)appName
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];;
}

- (NSString *)appVersion
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
}

- (NSString *)appBuild
{
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
}

- (NSString *)appBuildConfiguration
{
#if defined(DEBUG)
    return @"Debug";
#elif defined(ALPHA)
    return @"Alpha";
#endif

    // This little trick is the only way we can differentiate TestFlight from App Store, since the built app is identical
    if ([[[[NSBundle mainBundle] appStoreReceiptURL] lastPathComponent] isEqualToString:@"sandboxReceipt"]) {
        return @"Beta";
    } else {
        return @"Production";
    }
}

@end
