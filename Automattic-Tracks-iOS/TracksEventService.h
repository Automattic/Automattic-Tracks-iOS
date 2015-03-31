#import <Foundation/Foundation.h>
#import "TracksEvent.h"
#import <CoreData/CoreData.h>

@interface TracksEventService : NSObject

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (TracksEvent *)createTracksEventWithName:(NSString *)name;

- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                  username:(NSString *)username
                                 userAgent:(NSString *)userAgent
                                  userType:(NSString *)userType
                                 eventDate:(NSDate *)date;

@end
