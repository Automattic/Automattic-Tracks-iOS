#import "NSArray+objectsAfterIndex.h"

@implementation NSArray (NSArray_withObjectsToPrune)

- (NSArray *)objectsAfterIndex:(int) index{

    NSUInteger count = self.count;

    if(count <= index){
        return @[];
    }

    NSUInteger rangeStart = index;
    NSUInteger rangeEnd = self.count - index - 1;

    return [self subarrayWithRange:NSMakeRange(rangeStart, rangeEnd)];
}

@end
