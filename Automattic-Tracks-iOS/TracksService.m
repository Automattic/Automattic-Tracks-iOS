#import "TracksService.h"
#import "TracksDeviceInformation.h"

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
    TracksDeviceInformation *deviceInformation = [TracksDeviceInformation new];
    
    NSString *REQUEST_TIMESTAMP_KEY = @"_rt";
    NSString *DEVICE_HEIGHT_PIXELS_KEY = @"_ht";
    NSString *DEVICE_WIDTH_PIXELS_KEY = @"_wd";
    NSString *DEVICE_LANG_KEY = @"_lg";
    NSString *DEVICE_INFO_PREFIX = @"device_info_";
    NSString *deviceInfoAppName = [NSString stringWithFormat:@"%@app_name", DEVICE_INFO_PREFIX];
    NSString *deviceInfoAppVersion = [NSString stringWithFormat:@"%@app_version", DEVICE_INFO_PREFIX];
    NSString *deviceInfoAppBuild = [NSString stringWithFormat:@"%@app_version_code", DEVICE_INFO_PREFIX];
    NSString *deviceInfoOS = [NSString stringWithFormat:@"%@os", DEVICE_INFO_PREFIX];
    NSString *deviceInfoOSVersion = [NSString stringWithFormat:@"%@os_version", DEVICE_INFO_PREFIX];
    NSString *deviceInfoBrand = [NSString stringWithFormat:@"%@brand", DEVICE_INFO_PREFIX];
    NSString *deviceInfoManufacturer = [NSString stringWithFormat:@"%@manufacturer", DEVICE_INFO_PREFIX];
    NSString *deviceInfoModel = [NSString stringWithFormat:@"%@model", DEVICE_INFO_PREFIX];
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;

    return @{ REQUEST_TIMESTAMP_KEY : @(lround([NSDate date].timeIntervalSince1970 * 1000)),
              deviceInfoAppBuild : deviceInformation.appBuild,
              deviceInfoAppName : deviceInformation.appName,
              deviceInfoAppVersion : deviceInformation.appVersion,
              deviceInfoBrand : deviceInformation.brand,
              deviceInfoManufacturer : deviceInformation.manufacturer,
              deviceInfoModel : deviceInformation.model,
              deviceInfoOS : deviceInformation.os,
              deviceInfoOSVersion : deviceInformation.version,
              DEVICE_HEIGHT_PIXELS_KEY : @(screenSize.height),
              DEVICE_WIDTH_PIXELS_KEY : @(screenSize.width),
              DEVICE_LANG_KEY : deviceInformation.deviceLanguage,
              };
}

@end
