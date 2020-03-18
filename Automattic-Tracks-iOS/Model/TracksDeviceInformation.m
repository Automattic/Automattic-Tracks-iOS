#import "TracksDeviceInformation.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import "WatchSessionManager.h"
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

@end

@implementation TracksDeviceInformation

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
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
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

-(CGFloat)statusBarHeight{
#if TARGET_OS_IPHONE
    return [self statusBarFrame].size.height;
#else   // Mac
    return 0;
#endif
}

-(NSString *)orientation{
#if TARGET_OS_IPHONE
     UIInterfaceOrientation orientation = [self statusBarOrientation];
    
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
// This method was created because UIApplication.sharedApplication.statusBarFrame should only
// be called from the main thread.
//
- (CGRect)statusBarFrame {
    
    if ([NSThread isMainThread]) {
        return UIApplication.sharedApplication.statusBarFrame;
    }
    
    __block CGRect frame = CGRectZero;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        frame = UIApplication.sharedApplication.statusBarFrame;
    });
    
    return frame;
}
#endif

#if TARGET_OS_IPHONE
// This method was created because UIApplication.sharedApplication.statusBarOrientation should only
// be called from the main thread.
//
- (UIInterfaceOrientation)statusBarOrientation {
    if ([NSThread isMainThread]) {
        return UIApplication.sharedApplication.statusBarOrientation;
    }
    
    __block CGFloat orientation = 0;
    
    dispatch_sync(dispatch_get_main_queue(), ^{
        orientation = UIApplication.sharedApplication.statusBarOrientation;
    });
    
    return orientation;
}
#endif

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

@end
