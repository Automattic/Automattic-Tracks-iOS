#import "TracksDeviceInformation.h"
#import "WatchSessionManager.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
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
    return UIApplication.sharedApplication.statusBarFrame.size.height;
#else   // Mac
    return 0;
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

@end
