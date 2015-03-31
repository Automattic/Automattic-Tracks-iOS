#import "TracksService.h"
#import <FMDB.h>

@interface TracksService ()

@property (nonatomic, strong) NSMutableArray *simpleStorage;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) FMDatabase *database;

@end

static NSTimeInterval const EVENT_TIMER_FIVE_MINUTES = 5 * 60;
NSString *const TrackServiceDidSendQueuedEventsNotification = @"TrackServiceDidSendQueuedEventsNotification";

@implementation TracksService

- (instancetype)init
{
    self = [super init];
    if (self) {
        _simpleStorage = [NSMutableArray new];
        _remote = [TracksServiceRemote new];
        _queueSendInterval = EVENT_TIMER_FIVE_MINUTES;
        
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
        _database = [FMDatabase databaseWithPath:[NSString stringWithFormat:@"%@/tracks.db", basePath]];
        [_database open];
            
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
    
    if (events.count == 0) {
        [self resetTimer];
        return;
    }

    NSMutableArray *jsonEvents = [NSMutableArray arrayWithCapacity:events.count];
    for (TracksEvent *tracksEvent in events) {
        [jsonEvents addObject:tracksEvent.dictionaryRepresentation];
    }
    
    [self.remote sendBatchOfEvents:jsonEvents withSharedProperties:@{} completionHandler:^{
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
