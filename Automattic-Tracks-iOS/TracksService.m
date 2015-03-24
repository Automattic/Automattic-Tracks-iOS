#import "TracksService.h"

@interface TracksService ()

@property (nonatomic, strong) NSMutableArray *simpleStorage;
@property (nonatomic, strong) NSTimer *timer;

@end

static NSTimeInterval const EVENT_TIMER_FIVE_MINUTES = 5 * 60;

@implementation TracksService

- (instancetype)init
{
    self = [super init];
    if (self) {
        _simpleStorage = [NSMutableArray new];
        [self resetTimer];
    }
    
    return self;
}

- (void)trackEvent:(TracksEvent *)event
{
    NSParameterAssert(event != nil);
    
    [self.simpleStorage addObject:event];
}


- (NSUInteger)queuedEventCount
{
    return self.simpleStorage.count;
}


- (void)sendQueuedEvents
{
    NSLog(@"Sending queued events");
    [self.timer invalidate];
    
    NSArray *events = [NSArray arrayWithArray:self.simpleStorage];
    [self.simpleStorage removeAllObjects];
    
    __weak TracksService *weakSelf = self;
    [self.remote sendBatchOfEvents:events withSharedProperties:@{} completionHandler:^{
        // Assume no errors for now
        [weakSelf resetTimer];
    }];
}


- (void)resetTimer
{
    [self.timer invalidate];
    
    self.timer = [NSTimer timerWithTimeInterval:EVENT_TIMER_FIVE_MINUTES target:self selector:@selector(sendQueuedEvents) userInfo:nil repeats:NO];
}

- (void)dealloc
{
    [self.timer invalidate];
}

@end
