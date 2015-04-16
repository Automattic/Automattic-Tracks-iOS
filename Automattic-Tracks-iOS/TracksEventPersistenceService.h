#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TracksEvent.h"

@interface TracksEventPersistenceService : NSObject

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)persistTracksEvent:(TracksEvent *)tracksEvent;

- (NSArray *)fetchAllTracksEvents;

- (NSUInteger)countAllTracksEvents;

- (void)removeTracksEvents:(NSArray *)tracksEvents;

- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents;

@end
