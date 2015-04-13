#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TracksEvent.h"

@interface TracksEventTests : XCTestCase

@property (nonatomic, strong) TracksEvent *subject;

@end

@implementation TracksEventTests

- (void)setUp
{
    [super setUp];
    
    self.subject = [TracksEvent new];
    self.subject.eventName = @"test";
    self.subject.userID = @"anonymous123";
}

- (void)tearDown
{
    [super tearDown];
    
    self.subject = nil;
}

- (void)testInitNotNil
{
    XCTAssertNotNil(self.subject);
}

- (void)testInitNotNilDate
{
    XCTAssertNotNil(self.subject.date);
}

- (void)testInitNotNilUUID
{
    XCTAssertNotNil(self.subject.uuid);
}

- (void)testInitNotNilCustomProperties
{
    XCTAssertNotNil(self.subject.customProperties);
    XCTAssertEqual(0, self.subject.customProperties.count);
}

@end
