#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>
#import "TracksEvent.h"

NS_ASSUME_NONNULL_BEGIN

@interface TracksEventPersistenceService : NSObject

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;

- (void)persistTracksEvent:(TracksEvent *)tracksEvent;

- (NSArray *)fetchAllTracksEvents;

- (NSUInteger)countAllTracksEvents;

- (void)removeTracksEvents:(NSArray *)tracksEvents;

- (void)clearTracksEvents;

- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents;
- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents onComplete:(nullable void(^)())completion;

@end

NS_ASSUME_NONNULL_END
