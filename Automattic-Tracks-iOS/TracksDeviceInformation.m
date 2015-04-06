#import "TracksDeviceInformation.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <UIDeviceHardware.h>

@implementation TracksDeviceInformation

- (NSString *)brand
{
    return @"Apple";
}


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


- (BOOL)isWiFiConnected
{
    // TODO - Implement this with Reachability
    return NO;
}


- (NSString *)deviceLanguage
{
    return [[NSLocale currentLocale] localeIdentifier];
}


- (NSString *)manufacturer
{
    return @"Apple";
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
