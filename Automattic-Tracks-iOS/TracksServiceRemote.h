#import <Foundation/Foundation.h>
#import "TracksEvent.h"

@interface TracksServiceRemote : NSObject

- (void)sendBatchOfEvents:(NSArray *)events withSharedProperties:(NSDictionary *)properties completionHandler:(void (^)(NSError *error))completion;

@end
