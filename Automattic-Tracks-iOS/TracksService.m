#import "TracksService.h"

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
    NSLog(@"Sending queued events");
    [self.timer invalidate];
    
    NSArray *events = [self.tracksEventService allTracksEvents];

    if (events.count == 0) {
        [self resetTimer];
        return;
    }

    NSMutableArray *jsonEvents = [NSMutableArray arrayWithCapacity:events.count];
    for (TracksEvent *tracksEvent in events) {
        [jsonEvents addObject:tracksEvent.dictionaryRepresentation];
    }
    
    [self.remote sendBatchOfEvents:jsonEvents withSharedProperties:@{} completionHandler:^{
        // Delete the events since they sent or errored
        [self.tracksEventService removeTracksEvents:events];
        
        // Assume no errors for now
        [self resetTimer];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:TrackServiceDidSendQueuedEventsNotification object:nil];
    }];
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

@end
