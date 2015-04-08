#import <Foundation/Foundation.h>
#import "TracksEvent.h"

@interface TracksServiceRemote : NSObject

- (void)sendSingleTracksEvent:(TracksEvent *)tracksEvent completionHandler:(void (^)(void))completion;
- (void)sendBatchOfEvents:(NSArray *)events withSharedProperties:(NSDictionary *)properties completionHandler:(void (^)(NSError *error))completion;

@end
