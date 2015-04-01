#import "TracksService.h"

#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>
#import <UIDeviceHardware.h>


@interface TracksService ()

@property (nonatomic, strong) NSTimer *timer;

@end

static NSTimeInterval const EVENT_TIMER_FIVE_MINUTES = 5 * 60;
NSString *const TrackServiceDidSendQueuedEventsNotification = @"TrackServiceDidSendQueuedEventsNotification";

@implementation TracksService

- (instancetype)init
{
    self = [super init];
    if (self) {
        _remote = [TracksServiceRemote new];
        _queueSendInterval = EVENT_TIMER_FIVE_MINUTES;
        _contextManager = [TracksContextManager new];
        _tracksEventService = [[TracksEventService alloc] initWithContextManager:_contextManager];
        
        [self resetTimer];
    }
    
    return self;
}

- (void)trackEventName:(NSString *)eventName
{
    NSParameterAssert(eventName.length > 0);
    
    [self.tracksEventService createTracksEventWithName:eventName];
}


- (NSUInteger)queuedEventCount
{
    return [self.tracksEventService numberOfTracksEvents];
}


- (void)sendQueuedEvents
{
    [self.timer invalidate];
    
    NSArray *events = [self.tracksEventService allTracksEvents];

    if (events.count == 0) {
        NSLog(@"No events to send.");
        [self resetTimer];
        return;
    }

    NSMutableArray *jsonEvents = [NSMutableArray arrayWithCapacity:events.count];
    for (TracksEvent *tracksEvent in events) {
        [jsonEvents addObject:tracksEvent.dictionaryRepresentation];
    }
    
    NSLog(@"Sending queued events");
    [self.remote sendBatchOfEvents:jsonEvents
              withSharedProperties:[self generateCommonProperties]
                 completionHandler:^{
                     // Delete the events since they sent or errored
                     [self.tracksEventService removeTracksEvents:events];
                     
                     // Assume no errors for now
                     [self resetTimer];
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:TrackServiceDidSendQueuedEventsNotification object:nil];
                 }
     ];
}


- (void)resetTimer
{
    [self.timer invalidate];
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.queueSendInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
}


- (void)timerFireMethod:(NSTimer *)timer
{
    [self sendQueuedEvents];
}


- (void)dealloc
{
    [self.timer invalidate];
}


- (void)setQueueSendInterval:(NSTimeInterval)queueSendInterval
{
    _queueSendInterval = queueSendInterval;
    [self resetTimer];
}

- (NSDictionary *)generateCommonProperties
{
    CTTelephonyNetworkInfo *netInfo = [CTTelephonyNetworkInfo new];
    CTCarrier *carrier = [netInfo subscriberCellularProvider];
    NSString *type = nil;
    if ([netInfo respondsToSelector:@selector(currentRadioAccessTechnology)]) {
        type = [netInfo currentRadioAccessTechnology];
    }
    NSString *carrierName = nil;
    if (carrier) {
        carrierName = [NSString stringWithFormat:@"%@ [%@/%@/%@]", carrier.carrierName, [carrier.isoCountryCode uppercaseString], carrier.mobileCountryCode, carrier.mobileNetworkCode];
    }
    
//    DDLogInfo(@"Reachability - WordPress.com - WiFi: %@  WWAN: %@  Carrier: %@  Type: %@", wifi, wwan, carrierName, type);

    NSString *REQUEST_TIMESTAMP_KEY = @"_rt";
    NSString *DEVICE_HEIGHT_PIXELS_KEY = @"_ht";
    NSString *DEVICE_WIDTH_PIXELS_KEY = @"_wd";
    NSString *DEVICE_LANG_KEY = @"_lg";
    NSString *DEVICE_INFO_PREFIX = @"device_info_";
    NSString *deviceInfoOS = [NSString stringWithFormat:@"%@os", DEVICE_INFO_PREFIX];
    NSString *deviceInfoOSVersion = [NSString stringWithFormat:@"%@os_version", DEVICE_INFO_PREFIX];
    NSString *deviceInfoBrand = [NSString stringWithFormat:@"%@brand", DEVICE_INFO_PREFIX];
    NSString *deviceInfoManufacturer = [NSString stringWithFormat:@"%@manufacturer", DEVICE_INFO_PREFIX];
    NSString *deviceInfoModel = [NSString stringWithFormat:@"%@model", DEVICE_INFO_PREFIX];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;

    return @{ REQUEST_TIMESTAMP_KEY : @(lround([NSDate date].timeIntervalSince1970 * 1000)),
              deviceInfoBrand : @"Apple",
              deviceInfoManufacturer : @"Apple",
              deviceInfoModel : [UIDeviceHardware platformString],
              deviceInfoOS : [[UIDevice currentDevice] systemName],
              deviceInfoOSVersion : [[UIDevice currentDevice] systemVersion],
              DEVICE_HEIGHT_PIXELS_KEY : @(screenSize.height),
              DEVICE_WIDTH_PIXELS_KEY : @(screenSize.width),
              DEVICE_LANG_KEY : [[NSLocale currentLocale] localeIdentifier],
              };
}

@end
