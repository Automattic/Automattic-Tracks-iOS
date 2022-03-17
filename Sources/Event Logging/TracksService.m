#import "TracksService.h"
#import "TracksDeviceInformation.h"
#import <Network/Network.h>

#if SWIFT_PACKAGE
@import AutomatticTracksModel;
@import AutomatticExperiments;
#else
#import <AutomatticTracks/AutomatticTracks-Swift.h>
#endif


#if TARGET_OS_IPHONE
#import <UIKit/UIKit.h>
#else
#import <AppKit/AppKit.h>
#endif

@interface TracksService ()

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) BOOL timerEnabled;
@property (nonatomic, assign) BOOL isHostReachable;
@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksDeviceInformation *deviceInformation;
@property (nonatomic, strong) nw_path_monitor_t networkMonitor;
/// The queue on which the Network framework will dispatch all the executions of the update and
/// cancel events handlers.
@property (nonatomic, strong) dispatch_queue_t networkMonitorQueue;
@property (nonatomic, strong) nw_path_t networkPath;

@property (nonatomic, readonly) NSString *userAgent;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *token;
@property (nonatomic, assign, getter=isAnonymous) BOOL anonymous;

@end

static NSTimeInterval const EVENT_TIMER_DEFAULT = 15; // seconds
NSString *const TrackServiceWillSendQueuedEventsNotification = @"TrackServiceDidSendQueuedEventsNotification";
NSString *const TrackServiceDidSendQueuedEventsNotification = @"TrackServiceDidSendQueuedEventsNotification";

NSString *const RequestTimestampKey = @"_rt";
NSString *const DeviceLanguageKey = @"_lg";
NSString *const DeviceInfoAppNameKey = @"device_info_app_name";
NSString *const DeviceInfoAppVersionKey = @"device_info_app_version";
NSString *const DeviceInfoAppBuildKey = @"device_info_app_version_code";
NSString *const DeviceInfoAppBuildConfigurationKey = @"device_info_app_build_configuration";
NSString *const DeviceInfoOSKey = @"device_info_os";
NSString *const DeviceInfoOSVersionKey = @"device_info_os_version";
NSString *const DeviceInfoBrandKey = @"device_info_brand";
NSString *const DeviceInfoManufacturerKey = @"device_info_manufacturer";
NSString *const DeviceInfoModelKey = @"device_info_model";
NSString *const DeviceInfoHeightKey = @"device_info_display_height";
NSString *const DeviceInfoWidthKey = @"device_info_display_width";
NSString *const DeviceInfoNetworkOperatorKey = @"device_info_current_network_operator";
NSString *const DeviceInfoRadioTypeKey = @"device_info_phone_radio_type";
NSString *const DeviceInfoWiFiConnectedKey = @"device_info_wifi_connected";
NSString *const DeviceInfoIsOnlineKey = @"device_info_is_online";
NSString *const DeviceInfoAppleWatchConnectedKey = @"device_info_apple_watch_connected";
NSString *const DeviceInfoVoiceOverEnabledKey = @"device_info_voiceover_enabled";
NSString *const DeviceInfoStatusBarHeightKey = @"device_info_status_bar_height";
NSString *const DeviceInfoOrientation = @"device_info_orientation";

NSString *const TracksEventNameKey = @"_en";
NSString *const TracksUserAgentKey = @"_via_ua";
NSString *const TracksTimestampKey = @"_ts";
NSString *const TracksUserTypeKey = @"_ut";
NSString *const TracksUserIDKey = @"_ui";
NSString *const TracksUsernameKey = @"_ul";

NSString *const TracksUserTypeAnonymous = @"anon";
NSString *const TracksUserTypeAuthenticated = @"wpcom:user_id";
NSString *const USER_ID_ANON = @"anonId";


@implementation TracksService

- (instancetype)initWithContextManager:(TracksContextManager *)contextManager
{
    self = [super init];
    if (self) {
        _eventNamePrefix = @"wpios";
        _anonymousUserTypeKey = TracksUserTypeAnonymous;
        _authenticatedUserTypeKey = TracksUserTypeAuthenticated;
        _remote = [TracksServiceRemote new];
        _remote.tracksUserAgent = self.userAgent;
        _queueSendInterval = EVENT_TIMER_DEFAULT;
        _contextManager = contextManager;
        _tracksEventService = [[TracksEventService alloc] initWithContextManager:contextManager];
        _deviceInformation = [TracksDeviceInformation new];

        [self startNetworkMonitor];
        [self updateDeviceInformationFromReachability];

        _isHostReachable = YES;
        _timerEnabled = YES;
        _userProperties = [NSMutableDictionary new];
        
        [self switchToAnonymousUserWithAnonymousID:[[NSUUID UUID] UUIDString]];
        [self resetTimer];
        

#if TARGET_OS_IPHONE
        NSNotificationCenter *defaultCenter = [NSNotificationCenter defaultCenter];
        [defaultCenter addObserver:self selector:@selector(didEnterBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
        [defaultCenter addObserver:self selector:@selector(didBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
#endif
    }
    return self;
}


- (void)dealloc
{
    [self.timer invalidate];

    if (self.networkMonitor != nil) {
        nw_path_monitor_cancel(self.networkMonitor);
    }
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
                                             userAgent:self.userAgent
                                              userType:self.isAnonymous ? TracksEventUserTypeAnonymous : TracksEventUserTypeAuthenticated
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
    [self.timer invalidate];
    [[NSNotificationCenter defaultCenter] postNotificationName:TrackServiceWillSendQueuedEventsNotification object:nil];
    
    NSArray *events = [self.tracksEventService allTracksEvents];

    if (events.count == 0) {
        [self resetTimer];
        return;
    }
    
    NSMutableDictionary *commonProperties = [NSMutableDictionary new];
    [commonProperties addEntriesFromDictionary:[self immutableDeviceProperties]];
    [commonProperties addEntriesFromDictionary:[self mutableDeviceProperties]];

    NSMutableArray *jsonEvents = [NSMutableArray arrayWithCapacity:events.count];
    for (TracksEvent *tracksEvent in events) {
        NSDictionary *eventJSON = [self dictionaryForTracksEvent:tracksEvent withParentCommonProperties:commonProperties];
        [jsonEvents addObject:eventJSON];
    }

    __weak __typeof(self) weakSelf = self;
    [self.remote sendBatchOfEvents:jsonEvents
              withSharedProperties:commonProperties
                 completionHandler:^(NSError *error) {
                     if (error) {
                         TracksLogError(@"TracksService Error while remote calling: %@", error);
                         [weakSelf.tracksEventService incrementRetryCountForEvents:events];
                     } else {
                         TracksLogVerbose(@"TracksService sendQueuedEvents completed. Sent %@ events.", @(events.count));
                         // Delete the events since they sent or errored
                         [weakSelf.tracksEventService removeTracksEvents:events];
                     }
                         
                     // Assume no errors for now
                     [weakSelf resetTimer];
                     
                     [[NSNotificationCenter defaultCenter] postNotificationName:TrackServiceDidSendQueuedEventsNotification object:nil];
                 }
     ];
}

- (void)clearQueuedEvents
{
    [self.tracksEventService clearTracksEvents];
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

- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID wpComToken:(NSString *)token skipAliasEventCreation:(BOOL)skipEvent
{
    [self switchToAuthenticatedUserWithUsername:username userID:userID skipAliasEventCreation:skipEvent];

    self.token = token;

    #if TARGET_OS_IPHONE
    [ExPlat configureWithPlatform:_eventNamePrefix oAuthToken:token userAgent:self.userAgent anonId:nil];
    #endif
}

- (void)switchToAnonymousUserWithAnonymousID:(NSString *)anonymousID
{
    NSParameterAssert(anonymousID.length > 0);
    
    self.anonymous = YES;
    self.username = @"";
    self.userID = anonymousID;
    self.token = nil;

    #if TARGET_OS_IPHONE
    [ExPlat configureWithPlatform:_eventNamePrefix oAuthToken:nil userAgent:self.userAgent anonId:anonymousID];
    #endif
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

#pragma mark - Reachability

/**
 * Update `self.deviceInformation` properties that rely on `self.reachability`.
 */
- (void)updateDeviceInformationFromReachability
{
    if (self.networkPath != nil) {
        nw_path_status_t pathStatus = nw_path_get_status(self.networkPath);
        self.deviceInformation.isWiFiConnected = nw_path_uses_interface_type(self.networkPath, nw_interface_type_wifi);
        self.deviceInformation.isOnline = (pathStatus == nw_path_status_satisfied || pathStatus == nw_path_status_satisfiable);
    } else {
        self.deviceInformation.isWiFiConnected = NO;
        self.deviceInformation.isOnline = NO;
    }
}

- (void)networkPathChanged:(nw_path_t)networkPath
{
    self.networkPath = networkPath;

    [self updateDeviceInformationFromReachability];

    if (self.deviceInformation.isOnline && self.isHostReachable == NO) {

        TracksLogVerbose(@"Tracks host is available. Enabling timer.");
        self.isHostReachable = YES;
        self.timerEnabled = YES;
        [self resetTimer];
    } else if (self.deviceInformation.isOnline == NO && self.isHostReachable == YES){
        TracksLogVerbose(@"Tracks host is unavailable. Disabling timer.");
        self.isHostReachable = NO;
        self.timerEnabled = NO;
        [self resetTimer];
    }
}

#pragma mark - Private methods

- (void)didEnterBackground:(NSNotification *)notification
{
    self.timerEnabled = NO;
    [self stopNetworkMonitor];
    [self sendQueuedEvents];
}


- (void)didBecomeActive:(NSNotification *)notification
{
    self.timerEnabled = YES;
    [self startNetworkMonitor];
    [self resetTimer];
}

- (void)resetTimer
{
    [self.timer invalidate];
    
    if (self.timerEnabled) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:self.queueSendInterval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:NO];
    }
}

- (void)startNetworkMonitor {
    if (self.networkMonitor != nil) {
        return;
    }

    self.networkMonitor = nw_path_monitor_create();

    // Create and set a queue for where the monitor can execute it's event handlers.
    //
    // Without one, the update handler doesn't get called when the monitor starts.
    dispatch_queue_attr_t attrs = dispatch_queue_attr_make_with_qos_class(
                                                                          DISPATCH_QUEUE_SERIAL,
                                                                          0,
                                                                          0 // The relative priority within the QOS class. Can range from 0 to -15.
                                                                          );
    self.networkMonitorQueue = dispatch_queue_create("com.automattic.tracks.network.monitor", attrs);
    nw_path_monitor_set_queue(self.networkMonitor, self.networkMonitorQueue);

    __weak typeof(self) weakSelf = self;
    nw_path_monitor_set_update_handler(self.networkMonitor, ^(nw_path_t _Nonnull path) {
        [weakSelf networkPathChanged:path];
    });
    nw_path_monitor_start(self.networkMonitor);
}

- (void)stopNetworkMonitor {
    if (self.networkMonitor != nil) {
        nw_path_monitor_cancel(self.networkMonitor);
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
#if TARGET_OS_IPHONE
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
#else
    CGSize screenSize = [[NSScreen mainScreen] frame].size;
#endif
    
    long long since1970millis = [NSDate date].timeIntervalSince1970 * 1000;

    return @{ RequestTimestampKey : @(since1970millis),
              DeviceInfoAppBuildKey : self.deviceInformation.appBuild ?: @"Unknown",
              DeviceInfoAppBuildConfigurationKey: self.deviceInformation.appBuildConfiguration,
              DeviceInfoAppNameKey : self.deviceInformation.appName ?: @"Unknown",
              DeviceInfoAppVersionKey : self.deviceInformation.appVersion ?: @"Unknown",
              DeviceInfoBrandKey : self.deviceInformation.brand,
              DeviceInfoManufacturerKey : self.deviceInformation.manufacturer,
              DeviceInfoModelKey : self.deviceInformation.model ?: @"Unknown",
              DeviceInfoOSKey : self.deviceInformation.os,
              DeviceInfoOSVersionKey : self.deviceInformation.version,
              DeviceInfoHeightKey : @(screenSize.height),
              DeviceInfoWidthKey : @(screenSize.width),
              DeviceLanguageKey : self.deviceInformation.deviceLanguage,
              TracksUserAgentKey : self.userAgent,
              };
}

- (NSDictionary *)mutableDeviceProperties
{
    // These properties change often and should be overridden in TracksEvents if they differ
    return @{DeviceInfoNetworkOperatorKey : self.deviceInformation.currentNetworkOperator ?: @"Unknown",
             DeviceInfoRadioTypeKey : self.deviceInformation.currentNetworkRadioType ?: @"Unknown",
             DeviceInfoWiFiConnectedKey : self.deviceInformation.isWiFiConnected ? @"YES" : @"NO",
             DeviceInfoIsOnlineKey : self.deviceInformation.isOnline ? @"YES" : @"NO",
             DeviceInfoVoiceOverEnabledKey : self.deviceInformation.isVoiceOverEnabled ? @"YES" : @"NO",
             DeviceInfoAppleWatchConnectedKey : self.deviceInformation.isAppleWatchConnected ? @"YES" : @"NO",
             DeviceInfoVoiceOverEnabledKey : self.deviceInformation.isVoiceOverEnabled ? @"YES" : @"NO",
             DeviceInfoAppleWatchConnectedKey : self.deviceInformation.isAppleWatchConnected ? @"YES" : @"NO",
             DeviceInfoStatusBarHeightKey : [NSNumber numberWithFloat:self.deviceInformation.statusBarHeight],
             DeviceInfoOrientation : self.deviceInformation.orientation ?: @"Unknown",
      };
}

- (NSDictionary *)dictionaryForTracksEvent:(TracksEvent *)tracksEvent withParentCommonProperties:(NSDictionary *)parentCommonProperties
{
    NSParameterAssert(tracksEvent);
    
    NSTimeInterval since1970 = tracksEvent.date.timeIntervalSince1970;
    long long since1970millis = since1970 * 1000;
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[TracksEventNameKey] = tracksEvent.eventName;
    dict[TracksTimestampKey] = @(since1970millis);
    
    if (tracksEvent.userType == TracksEventUserTypeAnonymous) {
        dict[TracksUserTypeKey] = self.anonymousUserTypeKey;
        dict[TracksUserIDKey] = tracksEvent.userID;
    } else {
        dict[TracksUserTypeKey] = self.authenticatedUserTypeKey;
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

- (NSString *)userAgent
{
    #if TARGET_OS_IPHONE
        return [NSString stringWithFormat:@"Nosara Client for iOS %@", TracksLibraryVersion];
    #endif

    #if TARGET_OS_MAC
        return [NSString stringWithFormat:@"Nosara Client for macOS %@", TracksLibraryVersion];
    #endif

    return [NSString stringWithFormat:@"Nosara Client for Objective-C %@", TracksLibraryVersion];
}

@end
