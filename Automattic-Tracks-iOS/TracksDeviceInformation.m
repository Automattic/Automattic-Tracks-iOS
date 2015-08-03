#import "TracksDeviceInformation.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <UIDeviceHardware.h>
#import <Reachability/Reachability.h>

@interface TracksDeviceInformation ()

@property (nonatomic, strong) Reachability *reachability;
@property (nonatomic, assign) BOOL isReachable;
@property (nonatomic, assign) BOOL isReachableByWiFi;
@property (nonatomic, assign) BOOL isReachableByWWAN;

@end

@implementation TracksDeviceInformation

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self setupReachability];
    }
    return self;
}


- (void)dealloc
{
    [self.reachability stopNotifier];
}


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
    return self.isReachableByWiFi;
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

- (void)setupReachability
{
    __weak TracksDeviceInformation *weakSelf = self;
    
    _reachability = [Reachability reachabilityWithHostname:@"public-api.wordpress.com"];
    _reachability.reachableBlock = ^(Reachability *reachability) {
        weakSelf.isReachable = reachability.isReachable;
        weakSelf.isReachableByWiFi = reachability.isReachableViaWiFi;
        weakSelf.isReachableByWWAN = reachability.isReachableViaWWAN;
    };
    
    _reachability.reachableBlock = ^(Reachability *reachability) {
        weakSelf.isReachable = reachability.isReachable;
        weakSelf.isReachableByWiFi = reachability.isReachableViaWiFi;
        weakSelf.isReachableByWWAN = reachability.isReachableViaWWAN;
    };
    
    [_reachability startNotifier];
}



@end
