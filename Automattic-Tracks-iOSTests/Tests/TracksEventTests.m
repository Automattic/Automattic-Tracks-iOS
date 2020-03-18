#import <Foundation/Foundation.h>
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

- (void)testEventNameValidationValid
{
    NSError *error;
    NSString *eventName = @"wpios_event_valid";
    self.subject.eventName = eventName;
    BOOL valid = [self.subject validateValue:&eventName forKey:@"eventName" error:&error];
    
    XCTAssertTrue(valid);
    XCTAssertNil(error);
    XCTAssertTrue([self.subject validateObject:nil]);
}

- (void)testEventNameValidationWhitespace
{
    NSError *error;
    NSString *eventName = @"wpios_ eventwith spaces";
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
    NSString *eventName = @"wpios_eventwith-dashes";
    self.subject.eventName = eventName;
    BOOL valid = [self.subject validateValue:&eventName forKey:@"eventName" error:&error];
    
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationEventNameDashes, error.code);
    XCTAssertFalse([self.subject validateObject:nil]);
}

- (void)testEventNameValidationUppercase
{
    NSError *error;
    NSString *eventName = @"wpios_eventWith_ashes";
    self.subject.eventName = eventName;
    BOOL valid = [self.subject validateValue:&eventName forKey:@"eventName" error:&error];
    
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationEventNamePatternMismatch, error.code);
    XCTAssertFalse([self.subject validateObject:nil]);
}

- (void)testCustomPropertiesNoProperties
{
    NSError *error;
    NSMutableDictionary *customProperties = self.subject.customProperties;
    
    BOOL valid = [self.subject validateValue:&customProperties forKey:@"customProperties" error:&error];
    
    XCTAssertNotNil(customProperties);
    XCTAssertTrue(valid);
    XCTAssertNil(error);
}

- (void)testCustomPropertiesValidProperty
{
    NSError *error;
    NSMutableDictionary *customProperties = self.subject.customProperties;
    customProperties[@"test_property"] = @"test value";
    
    BOOL valid = [self.subject validateValue:&customProperties forKey:@"customProperties" error:&error];
    
    XCTAssertNotNil(customProperties);
    XCTAssertTrue(valid);
    XCTAssertNil(error);
}

- (void)testCustomPropertiesInvalidPropertyWrongType
{
    NSError *error;
    NSMutableDictionary *customProperties = self.subject.customProperties;
    customProperties[@1] = @"test value";
    
    BOOL valid = [self.subject validateValue:&customProperties forKey:@"customProperties" error:&error];
    
    XCTAssertNotNil(customProperties);
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationCustomPropertiesKeyType, error.code);
}

- (void)testCustomPropertiesInvalidPropertyWrongKeyFormat
{
    NSError *error;
    NSMutableDictionary *customProperties = self.subject.customProperties;
    customProperties[@"_test"] = @"test value";
    
    BOOL valid = [self.subject validateValue:&customProperties forKey:@"customProperties" error:&error];
    
    XCTAssertNotNil(customProperties);
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationCustomPropertiesKeyFormat, error.code);
}

- (void)testDevicePropertiesNoProperties
{
    NSError *error;
    NSMutableDictionary *deviceProperties = self.subject.deviceProperties;
    
    BOOL valid = [self.subject validateValue:&deviceProperties forKey:@"deviceProperties" error:&error];
    
    XCTAssertNotNil(deviceProperties);
    XCTAssertTrue(valid);
    XCTAssertNil(error);
}

- (void)testDevicePropertiesValidProperty
{
    NSError *error;
    NSMutableDictionary *deviceProperties = self.subject.deviceProperties;
    deviceProperties[@"test_property"] = @"test value";
    
    BOOL valid = [self.subject validateValue:&deviceProperties forKey:@"deviceProperties" error:&error];
    
    XCTAssertNotNil(deviceProperties);
    XCTAssertTrue(valid);
    XCTAssertNil(error);
}

- (void)testDevicePropertiesInvalidPropertyWrongType
{
    NSError *error;
    NSMutableDictionary *deviceProperties = self.subject.deviceProperties;
    deviceProperties[@1] = @"test value";
    
    BOOL valid = [self.subject validateValue:&deviceProperties forKey:@"deviceProperties" error:&error];
    
    XCTAssertNotNil(deviceProperties);
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationDevicePropertiesKeyType, error.code);
}

- (void)testDevicePropertiesInvalidPropertyWrongKeyFormat
{
    NSError *error;
    NSMutableDictionary *deviceProperties = self.subject.deviceProperties;
    deviceProperties[@"_test"] = @"test value";
    
    BOOL valid = [self.subject validateValue:&deviceProperties forKey:@"deviceProperties" error:&error];
    
    XCTAssertNotNil(deviceProperties);
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationDevicePropertiesKeyFormat, error.code);
}

- (void)testUserPropertiesNoProperties
{
    NSError *error;
    NSMutableDictionary *userProperties = self.subject.userProperties;
    
    BOOL valid = [self.subject validateValue:&userProperties forKey:@"userProperties" error:&error];
    
    XCTAssertNotNil(userProperties);
    XCTAssertTrue(valid);
    XCTAssertNil(error);
}

- (void)testUserPropertiesValidProperty
{
    NSError *error;
    NSMutableDictionary *userProperties = self.subject.userProperties;
    userProperties[@"test_property"] = @"test value";
    
    BOOL valid = [self.subject validateValue:&userProperties forKey:@"userProperties" error:&error];
    
    XCTAssertNotNil(userProperties);
    XCTAssertTrue(valid);
    XCTAssertNil(error);
}

- (void)testUserPropertiesInvalidPropertyWrongType
{
    NSError *error;
    NSMutableDictionary *userProperties = self.subject.userProperties;
    userProperties[@1] = @"test value";
    
    BOOL valid = [self.subject validateValue:&userProperties forKey:@"userProperties" error:&error];
    
    XCTAssertNotNil(userProperties);
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationUserPropertiesKeyType, error.code);
}

- (void)testUserPropertiesInvalidPropertyWrongKeyFormat
{
    NSError *error;
    NSMutableDictionary *userProperties = self.subject.userProperties;
    userProperties[@"_test"] = @"test value";
    
    BOOL valid = [self.subject validateValue:&userProperties forKey:@"userProperties" error:&error];
    
    XCTAssertNotNil(userProperties);
    XCTAssertFalse(valid);
    XCTAssertNotNil(error);
    XCTAssertEqual(error.domain, TracksErrorDomain);
    XCTAssertEqual(TracksErrorCodeValidationUserPropertiesKeyFormat, error.code);
}





@end
