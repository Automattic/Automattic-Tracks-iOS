#import <Foundation/Foundation.h>
#import "TracksEvent.h"

@interface TracksService : NSObject

- (void)trackEvent:(TracksEvent *)event;

- (void)sendQueuedEvents;


@end
