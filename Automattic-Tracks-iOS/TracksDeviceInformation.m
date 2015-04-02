#import "TracksDeviceInformation.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <UIDeviceHardware.h>

@implementation TracksDeviceInformation

//CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
//CTCarrier *carrier = [netInfo subscriberCellularProvider];
//NSString *type = nil;
//if ([netInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
//    type = [netInfo currentRadioAccessTechnology];
//}
//NSString *carrierName = nil;
//if (carrier) {
//    carrierName = [NSString stringWithFormat:@"%@ [%@/%@/%@]", carrier.carrierName, [carrier.isoCountryCode uppercaseString], carrier.mobileCountryCode, carrier.mobileNetworkCode];
//}
//
//DDLogInfo(@"Reachability - WordPress.com - WiFi: %@  WWAN: %@  Carrier: %@  Type: %@", wifi, wwan, carrierName, type);


- (NSString *)brand
{
    return @"Apple";
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
    return [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"];;
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
