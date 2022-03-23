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

/// Increments the retry count for the specified events, and offers a completion closure with
/// error handling support.
/// 
- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents onComplete:(nullable void(^)(NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
