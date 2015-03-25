#import <Foundation/Foundation.h>
#import "TracksEvent.h"
#import "TracksServiceRemote.h"

extern NSString *const TrackServiceDidSendQueuedEventsNotification;

@interface TracksService : NSObject

@property (nonatomic, strong) TracksServiceRemote *remote;
@property (nonatomic, assign) NSTimeInterval queueSendInterval;
@property (nonatomic, readonly) NSUInteger queuedEventCount;

- (void)trackEvent:(TracksEvent *)event;

- (void)sendQueuedEvents;


@end
