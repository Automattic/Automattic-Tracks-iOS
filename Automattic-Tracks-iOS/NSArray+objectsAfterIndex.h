#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray (NSArray_withObjectsToPrune)
- (NSArray *)objectsAfterIndex:(int) index NS_SWIFT_NAME(objects(afterIndex:));
@end

NS_ASSUME_NONNULL_END
