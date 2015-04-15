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

- (void)testEventNameValidationNil
{
    NSError *error;
    self.subject.eventName = nil;
    BOOL valid = [self.subject validateValue:nil forKey:@"eventName" error:&error];
    
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationEventNameMissing, error.code);
    XCTAssertFalse([self.subject validateObject:nil]);
}

- (void)testEventNameValidationWhitespace
{
    NSError *error;
    NSString *eventName = @" eventWith Spaces";
    self.subject.eventName = eventName;
    BOOL valid = [self.subject validateValue:&eventName forKey:@"eventName" error:&error];
    
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationEventNameWhitespace, error.code);
    XCTAssertFalse([self.subject validateObject:nil]);
}

- (void)testEventNameValidationDashes
{
    NSError *error;
    NSString *eventName = @"eventWith-Dashes";
    self.subject.eventName = eventName;
    BOOL valid = [self.subject validateValue:&eventName forKey:@"eventName" error:&error];
    
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationEventNameDashes, error.code);
    XCTAssertFalse([self.subject validateObject:nil]);
}



@end
