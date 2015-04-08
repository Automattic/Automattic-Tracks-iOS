#import <UIKit/UIKit.h>
#import "TracksEvent.h"
#import "TracksEventService.h"
#import "TracksServiceRemote.h"

extern NSString *const TrackServiceWillSendQueuedEventsNotification;
extern NSString *const TrackServiceDidSendQueuedEventsNotification;

@interface TracksService : NSObject

@property (nonatomic, strong) TracksEventService *tracksEventService;
@property (nonatomic, strong) TracksServiceRemote *remote;

@property (nonatomic, assign) NSTimeInterval queueSendInterval;
@property (nonatomic, readonly) NSUInteger queuedEventCount;

@property (nonatomic, strong) NSDictionary *userProperties;

- (instancetype)initWithContextManager:(TracksContextManager *)contextManager;

- (void)switchToAuthenticatedUserWithUsername:(NSString *)username userID:(NSString *)userID skipAliasEventCreation:(BOOL)skipEvent;

- (void)switchToAnonymousUser;

- (void)trackEventName:(NSString *)eventName;

- (void)trackEventName:(NSString *)eventName withCustomProperties:(NSDictionary *)customProperties;

- (void)sendQueuedEvents;


@end
