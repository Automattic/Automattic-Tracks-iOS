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

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}


- (NSString *)brand
{
    return @"Apple";
}

- (NSString *)manufacturer
{
    return @"Apple";
}


#if TARGET_OS_IPHONE

- (NSString *)currentNetworkOperator
{
    #if TARGET_OS_SIMULATOR
        return @"Carrier (Simulator)";
    #else
        CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
        CTCarrier *carrier = [netInfo subscriberCellularProvider];

        NSString *carrierName = nil;
        if (carrier) {
            carrierName = [NSString stringWithFormat:@"%@ [%@/%@/%@]", carrier.carrierName, [carrier.isoCountryCode uppercaseString], carrier.mobileCountryCode, carrier.mobileNetworkCode];
        }

        return carrierName;
    #endif
}


- (NSString *)currentNetworkRadioType
{
    #if TARGET_OS_SIMULATOR
        return @"None (Simulator)";
    #else
        CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
        NSString *type = nil;
        if ([netInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
            type = [netInfo currentRadioAccessTechnology];
        }

        return type;
    #endif
}


- (NSString *)deviceLanguage
{
    return [[NSLocale currentLocale] localeIdentifier];
}

- (NSString *)model
{
    return [UIDeviceHardware platformString];
}


- (NSString *)os
{
    return [[UIDevice currentDevice] systemName];
}


- (NSString *)version
{
    return [[UIDevice currentDevice] systemVersion];
}

-(BOOL)isAppleWatchConnected{
    return [[WatchSessionManager shared] hasBeenPreviouslyPaired];
}

-(BOOL)isVoiceOverEnabled{
    return UIAccessibilityIsVoiceOverRunning();
}

-(CGFloat)statusBarHeight{
    return UIApplication.sharedApplication.statusBarFrame.size.height;
}

#else

- (NSString *)currentNetworkOperator
{
    return @"Not Applicable";
}


- (NSString *)currentNetworkRadioType
{
    return @"Unknown";
}


- (NSString *)deviceLanguage
{
    return [[NSLocale currentLocale] localeIdentifier];
}

- (NSString *)model
{
    size_t size;
    sysctlbyname("hw.model", NULL, &size, NULL, 0);
    char *model = malloc(size);
    sysctlbyname("hw.model", model, &size, NULL, 0);
    NSString *modelString = [NSString stringWithUTF8String:model];
    free(model);

    return modelString;
}

- (NSString *)os
{
    return @"OS X";
}

- (NSString *)version
{
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
}

-(BOOL)isVoiceOverEnabled
{
    Boolean exists = false;
    BOOL result = CFPreferencesGetAppBooleanValue(CFSTR("voiceOverOnOffKey"), CFSTR("com.apple.universalaccess"), &exists);

    if(exists){
        return result;
    }

    return NO;
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
