#import "TracksEventService.h"

@implementation TracksEventService

- (TracksEvent *)createTracksEventWithName:(NSString *)name
{
    return [self createTracksEventWithName:name eventDate:[NSDate date]];
}


- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                 eventDate:(NSDate *)date
{
    NSParameterAssert(name.length > 0);
    
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = name;
    
    return tracksEvent;
}


@end
