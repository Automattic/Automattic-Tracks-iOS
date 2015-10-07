#import "TracksDeviceInformation.h"

#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#import <UIDeviceIdentifier/UIDeviceHardware.h>
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#else
#import <AppKit/AppKit.h>
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
    CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];

    NSString *carrierName = nil;
    if (carrier) {
        carrierName = [NSString stringWithFormat:@"%@ [%@/%@/%@]", carrier.carrierName, [carrier.isoCountryCode uppercaseString], carrier.mobileCountryCode, carrier.mobileNetworkCode];
    }
    
    return carrierName;
}


- (NSString *)currentNetworkRadioType
{
    CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
    NSString *type = nil;
    if ([netInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
        type = [netInfo currentRadioAccessTechnology];
    }

    return type;
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

#else

- (NSString *)currentNetworkOperator
{
    return @"";
}


- (NSString *)currentNetworkRadioType
{
    return @"";
}


- (NSString *)deviceLanguage
{
    return [[NSLocale currentLocale] localeIdentifier];
}

- (NSString *)model
{
    return @"";
}


- (NSString *)os
{
    return @"OS X";
}


- (NSString *)version
{
    return [[NSProcessInfo processInfo] operatingSystemVersionString];
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
