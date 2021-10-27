#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WatchSessionManager : NSObject
+ (instancetype) shared;
- (BOOL)hasBeenPreviouslyPaired;
@end

NS_ASSUME_NONNULL_END
