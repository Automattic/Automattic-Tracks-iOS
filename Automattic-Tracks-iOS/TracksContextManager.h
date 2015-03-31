#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TracksContextManager : NSObject

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end
