#import "TracksEventService.h"

@interface TracksEventService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation TracksEventService

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    
}


- (TracksEvent *)createTracksEventWithName:(NSString *)name
{
    return [self createTracksEventWithName:name username:nil userAgent:nil userType:nil eventDate:[NSDate date]];
}


- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                  username:(NSString *)username
                                 userAgent:(NSString *)userAgent
                                  userType:(NSString *)userType
                                 eventDate:(NSDate *)date
{
    NSParameterAssert(name.length > 0);
    
    TracksEvent *tracksEvent = [NSEntityDescription insertNewObjectForEntityForName:@"TracksEvent" inManagedObjectContext:self.managedObjectContext];
    tracksEvent.eventName = name;
    tracksEvent.user = username;
    tracksEvent.userAgent = userAgent;
    tracksEvent.userType = userType;
    tracksEvent.date = date;
    
    NSError *error;
    BOOL success = [self.managedObjectContext save:&error];
    
    if (!success) {
        NSLog(@"Error saving: %@", error);
        return nil;
    }
    
    return tracksEvent;
}


@end
