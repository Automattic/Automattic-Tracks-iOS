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

- (void)testCustomPropertiesDictionaryRepresentationNoMatch
{
    self.subject.customProperties[@"Test"] = @"Value";
    
    NSDictionary *result = [self.subject dictionaryRepresentationWithParentCommonProperties:@{}];
    
    XCTAssertNotNil(result);
    XCTAssertTrue([[result objectForKey:@"Test"] isEqualToString:@"Value"]);
}

- (void)testCustomPropertiesDictionaryRepresentationExactMatch
{
    self.subject.customProperties[@"Test"] = @"Value";
    
    NSDictionary *result = [self.subject dictionaryRepresentationWithParentCommonProperties:@{@"Test" : @"Value"}];
    
    XCTAssertNotNil(result);
    XCTAssertNil([result objectForKey:@"Test"]);
}

- (void)testCustomPropertiesDictionaryRepresentationEventOverrides
{
    self.subject.customProperties[@"Test"] = @"Value2";
    
    NSDictionary *result = [self.subject dictionaryRepresentationWithParentCommonProperties:@{@"Test" : @"Value"}];
    
    XCTAssertNotNil(result);
    XCTAssertTrue([[result objectForKey:@"Test"] isEqualToString:@"Value2"]);
}

- (void)testUserAgentDictionaryRepresentationNoDefaultUA
{
    self.subject.userAgent = @"Meep Moop Beep Bloop";
    
    NSDictionary *result = [self.subject dictionaryRepresentationWithParentCommonProperties:@{}];
    
    XCTAssertTrue([[result objectForKey:@"_via_ua"] isEqualToString:self.subject.userAgent]);
}

- (void)testUserAgentDictionaryRepresentationNoMatch
{
    self.subject.userAgent = @"Meep Moop Beep Bloop";
    
    NSDictionary *result = [self.subject dictionaryRepresentationWithParentCommonProperties:@{@"_via_ua" : @"Test"}];
    
    XCTAssertTrue([[result objectForKey:@"_via_ua"] isEqualToString:self.subject.userAgent]);
}

- (void)testUserAgentDictionaryRepresentationExactMatch
{
    self.subject.userAgent = @"Meep Moop Beep Bloop";
    
    NSDictionary *result = [self.subject dictionaryRepresentationWithParentCommonProperties:@{@"_via_ua" : self.subject.userAgent}];
    
    XCTAssertNil([result objectForKey:@"_via_ua"]);
}

@end
