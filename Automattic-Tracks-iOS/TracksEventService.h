#import <Foundation/Foundation.h>
#import "TracksEvent.h"

@interface TracksEventService : NSObject

- (TracksEvent *)createTracksEventWithName:(NSString *)name;

- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                 eventDate:(NSDate *)date;

@end
