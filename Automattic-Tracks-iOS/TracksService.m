#import "TracksService.h"

@interface TracksService ()

@property (nonatomic, strong) NSMutableArray *simpleStorage;

@end

@implementation TracksService

- (void)trackEvent:(TracksEvent *)event
{
    NSParameterAssert(event != nil);
    
    [self.simpleStorage addObject:event];
}


- (void)sendQueuedEvents
{
    
}




@end
