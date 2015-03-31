#import <Foundation/Foundation.h>
#import "TracksEvent.h"
#import "TracksEventService.h"
#import "TracksServiceRemote.h"

extern NSString *const TrackServiceDidSendQueuedEventsNotification;

@interface TracksService : NSObject

@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksEventService *tracksEventService;
@property (nonatomic, strong) TracksServiceRemote *remote;
@property (nonatomic, assign) NSTimeInterval queueSendInterval;
@property (nonatomic, readonly) NSUInteger queuedEventCount;

- (void)trackEventName:(NSString *)eventName;

- (void)sendQueuedEvents;


@end
