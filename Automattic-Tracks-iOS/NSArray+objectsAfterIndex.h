#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (NSArray_withObjectsToPrune)
- (NSArray *)objectsAfterIndex:(int) index;
@end

NS_ASSUME_NONNULL_END
