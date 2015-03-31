#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TracksEventCoreData : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString * eventName;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSString * userAgent;
@property (nonatomic, retain) NSNumber * userType;
@property (nonatomic, retain) NSString * uuid;

@end
