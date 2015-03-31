#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TracksEvent.h"

@interface TracksEventPersistenceService : NSObject

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)persistTracksEvent:(TracksEvent *)tracksEvent;

@end
