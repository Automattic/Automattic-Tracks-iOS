#import <Foundation/Foundation.h>
#import "TracksEvent.h"

@interface TracksServiceRemote : NSObject

@property (nonatomic, strong) NSString * _Nullable tracksUserAgent;

- (void)sendBatchOfEvents:(NSArray<TracksEvent *> * _Nonnull)events
     withSharedProperties:(NSDictionary * _Nonnull)properties
        completionHandler:(void (^ _Nullable)(NSError * _Nullable error))completion;

@end
