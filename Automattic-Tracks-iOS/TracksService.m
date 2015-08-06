#import "TracksService.h"
#import "TracksDeviceInformation.h"
#import <CocoaLumberjack/CocoaLumberjack.h>
#import <Reachability/Reachability.h>

@interface TracksService ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL timerEnabled;
@property (nonatomic, assign) BOOL isHostReachable;
@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksDeviceInformation *deviceInformation;
@property (nonatomic, strong) Reachability *reachability;

@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, assign, getter=isAnonymous) BOOL anonymous;

@end

static NSTimeInterval const EVENT_TIMER_DEFAULT = 15; // seconds
NSString *const TrackServiceWillSendQueuedEventsNotification = @"TrackServiceDidSendQueuedEventsNotification";
NSString *const TrackServiceDidSendQueuedEventsNotification = @"TrackServiceDidSendQueuedEventsNotification";

NSString *const RequestTimestampKey = @"_rt";
NSString *const DeviceHeightPixelsKey = @"_ht";
NSString *const DeviceWidthPixelsKey = @"_wd";
NSString *const DeviceLanguageKey = @"_lg";
NSString *const DeviceInfoAppNameKey = @"device_info_app_name";
NSString *const DeviceInfoAppVersionKey = @"device_info_app_version";
NSString *const DeviceInfoAppBuildKey = @"device_info_app_version_code";
NSString *const DeviceInfoOSKey = @"device_info_os";
NSString *const DeviceInfoOSVersionKey = @"device_info_os_version";
NSString *const DeviceInfoBrandKey = @"device_info_brand";
NSString *const DeviceInfoManufacturerKey = @"device_info_manufacturer";
NSString *const DeviceInfoModelKey = @"device_info_model";
NSString *const DeviceInfoNetworkOperatorKey = @"device_info_current_network_operator";
NSString *const DeviceInfoRadioTypeKey = @"device_info_phone_radio_type";
NSString *const DeviceInfoWiFiConnectedKey = @"device_info_wifi_connected";

NSString *const TracksEventNameKey = @"_en";
NSString *const TracksUserAgentKey = @"_via_ua";
NSString *const TracksTimestampKey = @"_ts";
NSString *const TracksUserTypeKey = @"_ut";
NSString *const TracksUserIDKey = @"_ui";
NSString *const TracksUsernameKey = @"_ul";

NSString *const TracksUserTypeAnonymous = @"anon";
NSString *const TracksUserTypeWPCOM = @"wpcom:user_id";
NSString *const USER_ID_ANON = @"anonId";


@implementation TracksService

- (instancetype)initWithContextManager:(TracksContextManager *)contextManager
{
    self = [super init];
    if (self) {
        _eventNamePrefix = @"wpios";
        _remote = [TracksServiceRemote new];
        _queueSendInterval = EVENT_TIMER_DEFAULT;
        _contextManager = contextManager;
        _tracksEventService = [[TracksEventService alloc] initWithContextManager:contextManager];
        _deviceInformation = [TracksDeviceInformation new];
        _reachability = [Reachability reachabilityWithHostname:@"public-api.wordpress.com"];
        [_reachability startNotifier];
        _isHostReachable = YES;
        _timerEnabled = YES;
        _userProperties = [NSMutableDictionary new];
        
        [self switchToAnonymousUserWithAnonymousID:[[NSUUID UUID] UUIDString]];
        [self resetTimer];
        
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
        
        [defaultCenter addObserver:self selector:@selector(reachabilityChanged:) name:kReachabilityChangedNotification object:nil];
    }
    return self;
}


- (void)dealloc
{
    [self.timer invalidate];
    [self.reachability stopNotifier];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (void)trackEventName:(NSString *)eventName
{
    NSParameterAssert(eventName.length > 0);
    
    [self trackEventName:eventName withCustomProperties:nil];
}


- (void)trackEventName:(NSString *)eventName withCustomProperties:(NSDictionary *)customProperties
{
    eventName = [NSString stringWithFormat:@"%@_%@", self.eventNamePrefix, eventName];
    
    [self.tracksEventService createTracksEventWithName:eventName
                                              username:self.username
                                                userID:self.userID
                                             userAgent:nil
                                              userType:self.isAnonymous ? TracksEventUserTypeAnonymous : TracksEventUserTypeWordPressCom
                                             eventDate:[NSDate date]
                                      customProperties:customProperties
                                      deviceProperties:[self mutableDeviceProperties]
                                        userProperties:self.userProperties];
}

- (NSUInteger)queuedEventCount
{
    return [self.tracksEventService numberOfTracksEvents];
}


- (void)sendQueuedEvents
{
    DDLogVerbose(@"Tracks sendQueuedEvents Called...");
    
    [self.timer invalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:TrackServiceWillSendQueuedEventsNotification object:nil];
    
    NSArray *events = [self.tracksEventService allTracksEvents];

    if (events.count == 0) {
        [self resetTimer];
        return;
    }
    
    DDLogVerbose(@"Track sending events...");

    NSMutableDictionary *commonProperties = [NSMutableDictionary new];
    [commonProperties addEntriesFromDictionary:[self immutableDeviceProperties]];
    [commonProperties addEntriesFromDictionary:[self mutableDeviceProperties]];

    NSMutableArray *jsonEvents = [NSMutableArray arrayWithCapacity:events.count];
    for (TracksEvent *tracksEvent in events) {
        NSDictionary *eventJSON = [self dictionaryForTracksEvent:tracksEvent withParentCommonProperties:commonProperties];
        [jsonEvents addObject:eventJSON];
    }
    
    [self.remote sendBatchOfEvents:jsonEvents
              withSharedProperties:commonProperties
                 completionHandler:^(NSError *error) {
                     DDLogVerbose(@"Tracks sendQueuedEvents completed...");

                     if (error) {
                         DDLogError(@"TracksService Error while remote calling: %@", error);
                         [self.tracksEventService incrementRetryCountForEvents:events];
                     } else {
                         // Delete the events since they sent or errored
                         [self.tracksEventService removeTracksEvents:events];
                     }
                         
                     // Assume no errors for now
                     [self resetTimer];
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:TrackServiceDidSendQueuedEventsNotification object:nil];
                 }
     ];
}


- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID skipAliasEventCreation:(BOOL)skipEvent
{
    NSParameterAssert(username.length != 0 || userID.length != 0);
    
    NSString *previousUserID = self.userID;
    
    self.anonymous = NO;
    self.username = username;
    self.userID = userID;
    
    if (skipEvent == NO && previousUserID.length > 0) {
       [self.tracksEventService createTracksEventForAliasingWordPressComUser:username userID:userID withAnonymousUserID:previousUserID];
    }
}


- (void)switchToAnonymousUserWithAnonymousID:(NSString *)anonymousID
{
    NSParameterAssert(anonymousID.length > 0);
    
    self.anonymous = YES;
    self.username = @"";
    self.userID = anonymousID;
}


- (void)setRemoteCallsEnabled:(BOOL)remoteCallsEnabled
{
    _remoteCallsEnabled = remoteCallsEnabled;
    
    if (remoteCallsEnabled) {
        [self resetTimer];
    } else {
        [self.timer invalidate];
    }
}

#pragma mark - Private methods

- (void)didEnterBackground:(NSNotification *)notification
{
    self.timerEnabled = NO;
    [self.reachability stopNotifier];
    [self sendQueuedEvents];
}


- (void)didBecomeActive:(NSNotification *)notification
{
    self.timerEnabled = YES;
    [self.reachability startNotifier];
    [self resetTimer];
}


- (void)reachabilityChanged:(NSNotification *)notification
{
    Reachability *reachability = (Reachability *)notification.object;
    
    // Because the containing app may already use Reachability, limit this to ours only.
    if (reachability != self.reachability) {
        return;
    }

    self.deviceInformation.isWiFiConnected = reachability.isReachableViaWiFi;
    
    if (reachability.isReachable == YES && self.isHostReachable == NO) {
        DDLogVerbose(@"Tracks host is available. Enabling timer.");
        self.isHostReachable = YES;
        self.timerEnabled = YES;
        [self resetTimer];
    } else if (reachability.isReachable == NO && self.isHostReachable == YES){
        DDLogVerbose(@"Tracks host is unavailable. Disabling timer.");
        self.isHostReachable = NO;
        self.timerEnabled = NO;
        [self resetTimer];
    }
}


- (void)resetTimer
{
    [self.timer invalidate];
    
    if (self.timerEnabled) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.queueSendInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
    }
}


- (void)timerFireMethod:(NSTimer *)timer
{
    [self sendQueuedEvents];
}


- (void)setQueueSendInterval:(NSTimeInterval)queueSendInterval
{
    _queueSendInterval = queueSendInterval;
    [self resetTimer];
}

- (NSDictionary *)immutableDeviceProperties
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    
    return @{ RequestTimestampKey : @(lround([NSDate date].timeIntervalSince1970 * 1000)),
              DeviceInfoAppBuildKey : self.deviceInformation.appBuild ?: @"Unknown",
              DeviceInfoAppNameKey : self.deviceInformation.appName ?: @"Unknown",
              DeviceInfoAppVersionKey : self.deviceInformation.appVersion ?: @"Unknown",
              DeviceInfoBrandKey : self.deviceInformation.brand ?: @"Unknown",
              DeviceInfoManufacturerKey : self.deviceInformation.manufacturer ?: @"Unknown",
              DeviceInfoModelKey : self.deviceInformation.model ?: @"Unknown",
              DeviceInfoOSKey : self.deviceInformation.os ?: @"Unknown",
              DeviceInfoOSVersionKey : self.deviceInformation.version ?: @"Unknown",
              DeviceHeightPixelsKey : @(screenSize.height) ?: @0,
              DeviceWidthPixelsKey : @(screenSize.width) ?: @0,
              DeviceLanguageKey : self.deviceInformation.deviceLanguage ?: @"Unknown",
              TracksUserAgentKey : [NSString stringWithFormat:@"Nosara Client for iOS %@", TracksLibraryVersion],
              };
}

- (NSDictionary *)mutableDeviceProperties
{
    // These properties change often and should be overridden in TracksEvents if they differ
    return @{DeviceInfoNetworkOperatorKey : self.deviceInformation.currentNetworkOperator ?: @"Unknown",
             DeviceInfoRadioTypeKey : self.deviceInformation.currentNetworkRadioType ?: @"Unknown",
             DeviceInfoWiFiConnectedKey : self.deviceInformation.isWiFiConnected ? @"YES" : @"NO"
             };
}

- (NSDictionary *)dictionaryForTracksEvent:(TracksEvent *)tracksEvent withParentCommonProperties:(NSDictionary *)parentCommonProperties
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[TracksEventNameKey] = tracksEvent.eventName;
    dict[TracksTimestampKey] = @(lround(tracksEvent.date.timeIntervalSince1970 * 1000));
    
    if (tracksEvent.userType == TracksEventUserTypeAnonymous) {
        dict[TracksUserTypeKey] = TracksUserTypeAnonymous;
        dict[TracksUserIDKey] = tracksEvent.userID;
    } else {
        dict[TracksUserTypeKey] = TracksUserTypeWPCOM;
        dict[TracksUserIDKey] = tracksEvent.userID;
        dict[TracksUsernameKey] = tracksEvent.username;
    }
    
    // Only add objects that don't exist in parent or are different than parent
    for (id key in tracksEvent.customProperties.keyEnumerator) {
        if (parentCommonProperties[key] != nil && [parentCommonProperties[key] isEqual:tracksEvent.customProperties[key]]) {
            continue;
        }
        
        dict[key] = tracksEvent.customProperties[key];
    }
    
    for (id key in tracksEvent.userProperties.keyEnumerator) {
        if (parentCommonProperties[key] != nil && [parentCommonProperties[key] isEqual:tracksEvent.userProperties[key]]) {
            continue;
        }
        
        dict[key] = tracksEvent.userProperties[key];
    }
    
    for (id key in tracksEvent.deviceProperties.keyEnumerator) {
        if (parentCommonProperties[key] != nil && [parentCommonProperties[key] isEqual:tracksEvent.deviceProperties[key]]) {
            continue;
        }
        
        dict[key] = tracksEvent.deviceProperties[key];
    }
    
    if (tracksEvent.userAgent.length > 0 && ![parentCommonProperties[TracksUserAgentKey] isEqualToString:tracksEvent.userAgent]) {
        dict[TracksUserAgentKey] = tracksEvent.userAgent;
    }
    
    return dict;
}

@end
