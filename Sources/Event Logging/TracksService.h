#import <Foundation/Foundation.h>
#import "TracksEvent.h"
#import "TracksEventService.h"
#import "TracksServiceRemote.h"

extern NSString *const TrackServiceWillSendQueuedEventsNotification;
extern NSString *const TrackServiceDidSendQueuedEventsNotification;

@interface TracksService : NSObject

@property (nonatomic, strong) TracksEventService *tracksEventService;
@property (nonatomic, strong) TracksServiceRemote *remote;

/*! Used to configure the ExPlat `platform` property. If this property is `nil`, the `eventNamePrefix` property is used instead. Default is `nil`. */
@property (nonatomic, copy) NSString *platform;

@property (nonatomic, copy) NSString *eventNamePrefix;
@property (nonatomic, copy) NSString *anonymousUserTypeKey;
@property (nonatomic, copy) NSString *authenticatedUserTypeKey;

@property (nonatomic, assign) NSTimeInterval queueSendInterval;
@property (nonatomic, readonly) NSUInteger queuedEventCount;
@property (nonatomic, assign) BOOL remoteCallsEnabled;

@property (nonatomic, readonly) NSMutableDictionary *userProperties;

- (instancetype) init __attribute__((unavailable("init not available")));
- (instancetype)initWithContextManager:(TracksContextManager *)contextManager NS_DESIGNATED_INITIALIZER;

- (NSDictionary *)dictionaryForTracksEvent:(TracksEvent *)tracksEvent withParentCommonProperties:(NSDictionary *)parentCommonProperties;

- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID skipAliasEventCreation:(BOOL)skipEvent;
- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID wpComToken:(NSString *)token skipAliasEventCreation:(BOOL)skipEvent;
- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID anonymousID:(NSString *)anonymousID wpComToken:(NSString *)token skipAliasEventCreation:(BOOL)skipEvent;
- (void)switchToAnonymousUserWithAnonymousID:(NSString *)anonymousID;

- (void)trackEventName:(NSString *)eventName;
- (void)trackEventName:(NSString *)eventName withCustomProperties:(NSDictionary *)customProperties;

- (void)sendQueuedEvents;
- (void)clearQueuedEvents;

@end
