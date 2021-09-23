#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

@import AutomatticTracksEvents;
#import "TestTracksContextManager.h"

@interface TracksServiceTests : XCTestCase

@property (nonatomic, strong) TracksService *subject;
@property (nonatomic, strong) TracksServiceRemote *tracksServiceRemote;
@property (nonatomic, strong) TracksEventService *tracksEventService;
@property (nonatomic, strong) TestTracksContextManager *contextManager;

@end

@implementation TracksServiceTests

- (void)setUp {
    [super setUp];

    self.contextManager = [TestTracksContextManager new];
    self.subject = [[TracksService alloc] initWithContextManager:self.contextManager];
    
    self.tracksServiceRemote = OCMClassMock([TracksServiceRemote class]);
    self.tracksEventService = OCMClassMock([TracksEventService class]);
    
    self.subject.tracksEventService = self.tracksEventService;
    self.subject.remote = self.tracksServiceRemote;
}


- (void)tearDown {
    [super tearDown];
    
    self.subject = nil;
    self.contextManager = nil;
    self.tracksEventService = nil;
    self.tracksServiceRemote = nil;
}


- (void)testNoEvents
{
    XCTAssertEqual(0, self.subject.queuedEventCount);
}


- (void)testTrackEvent
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"Test";
    tracksEvent.userID = @"anonymous123";
    OCMExpect([self.tracksEventService createTracksEventWithName:[OCMArg isEqual:@"wpios_Test"]
                                                        username:[OCMArg any]
                                                          userID:[OCMArg isNotNil]
                                                       userAgent:[OCMArg any]
                                                        userType:TracksEventUserTypeAnonymous
                                                       eventDate:[OCMArg isNotNil]
                                                customProperties:[OCMArg any]
                                                deviceProperties:[OCMArg any]
                                                  userProperties:[OCMArg any]])
    .andReturn(tracksEvent);
    
    [self.subject trackEventName:@"Test"];
    
    OCMVerifyAll((id)self.tracksEventService);
}


- (void)testTrackEventOverriddenSource
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"Test";
    tracksEvent.userID = @"anonymous123";
    OCMExpect([self.tracksEventService createTracksEventWithName:[OCMArg isEqual:@"wpios2_Test"]
                                                        username:[OCMArg any]
                                                          userID:[OCMArg isNotNil]
                                                       userAgent:[OCMArg any]
                                                        userType:TracksEventUserTypeAnonymous
                                                       eventDate:[OCMArg isNotNil]
                                                customProperties:[OCMArg any]
                                                deviceProperties:[OCMArg any]
                                                  userProperties:[OCMArg any]])
    .andReturn(tracksEvent);
    
    self.subject.eventNamePrefix = @"wpios2";
    [self.subject trackEventName:@"Test"];
    
    OCMVerifyAll((id)self.tracksEventService);
}


/*
 * sendQueuedEvents methods
 */

- (void)testSendQueuedEventsOneEvent
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"Test";
    tracksEvent.userID = @"anonymous123";
    NSArray *events = @[tracksEvent];
    OCMExpect([self.tracksEventService allTracksEvents]).andReturn(events);
    
    OCMExpect([self.subject.remote sendBatchOfEvents:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssertTrue([obj isKindOfClass:[NSArray class]]);
        
        return ([obj count] == 1);
    }]
                              withSharedProperties:[OCMArg isNotNil]
                                 completionHandler:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)(NSError*)) {
        passedBlock(nil);
        
        return YES;
    }]]);
    
    [self expectationForNotification:TrackServiceDidSendQueuedEventsNotification object:nil handler:nil];

    [self.subject sendQueuedEvents];
    
    [self waitForExpectationsWithTimeout:2.0 handler:nil];
    
    OCMVerifyAll((id)self.subject.remote);
}


- (void)testSendQueuedEventsNoEvents
{
    [self.subject sendQueuedEvents];
    
    OCMVerifyAll((id)self.subject.remote);
}


/*
 * dictionaryForTracksEvent:withParentCommonProperties: methods
 */

- (void)testCustomPropertiesDictionaryRepresentationNoMatch
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"test";
    tracksEvent.userID = @"anonymous123";
    tracksEvent.customProperties[@"Test"] = @"Value";
    
    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{}];
    
    XCTAssertNotNil(result);
    XCTAssertTrue([[result objectForKey:@"Test"] isEqualToString:@"Value"]);
}

- (void)testCustomPropertiesDictionaryRepresentationExactMatch
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"test";
    tracksEvent.userID = @"anonymous123";
    tracksEvent.customProperties[@"Test"] = @"Value";
    
    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{@"Test" : @"Value"}];
    
    XCTAssertNotNil(result);
    XCTAssertNil([result objectForKey:@"Test"]);
}

- (void)testCustomPropertiesDictionaryRepresentationEventOverrides
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"test";
    tracksEvent.userID = @"anonymous123";
    tracksEvent.customProperties[@"Test"] = @"Value2";
    
    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{@"Test" : @"Value"}];
    
    XCTAssertNotNil(result);
    XCTAssertTrue([[result objectForKey:@"Test"] isEqualToString:@"Value2"]);
}

- (void)testDictionaryForTracksEventMultipleProperties
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.userID = @"anonymous123";
    tracksEvent.eventName = @"log_special_condition";
    tracksEvent.customProperties[@"error_condition"] = @"WPStatsServiceRemote operationForVisitsForDate:andUnit:withCompletionHandler";
    tracksEvent.customProperties[@"error_details"] = @"This is a test of the emergency broadcast system";
    tracksEvent.deviceProperties[@"device_property1"] = @"test";
    tracksEvent.userProperties[@"user_property1"] = @"test";

    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{@"user_property1" : @"Value"}];
    
    XCTAssertNotNil(result);
    XCTAssertTrue([[result objectForKey:@"user_property1"] isEqualToString:@"test"]);
}

- (void)testUserAgentDictionaryRepresentationNoDefaultUA
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"test";
    tracksEvent.userID = @"anonymous123";
    tracksEvent.customProperties[@"Test"] = @"Value";
    tracksEvent.userAgent = @"Meep Moop Beep Bloop";
    
    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{}];
    
    XCTAssertTrue([[result objectForKey:@"_via_ua"] isEqualToString:tracksEvent.userAgent.copy]);
}

- (void)testUserAgentDictionaryRepresentationNoMatch
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"test";
    tracksEvent.userID = @"anonymous123";
    tracksEvent.customProperties[@"Test"] = @"Value";
    tracksEvent.userAgent = @"Meep Moop Beep Bloop";
    
    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{@"_via_ua" : @"Test"}];
    
    XCTAssertTrue([[result objectForKey:@"_via_ua"] isEqualToString:tracksEvent.userAgent.copy]);
}

- (void)testUserAgentDictionaryRepresentationExactMatch
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"test";
    tracksEvent.userID = @"anonymous123";
    tracksEvent.customProperties[@"Test"] = @"Value";
    tracksEvent.userAgent = @"Meep Moop Beep Bloop";
    
    NSDictionary *result = [self.subject dictionaryForTracksEvent:tracksEvent withParentCommonProperties:@{@"_via_ua" : tracksEvent.userAgent.copy}];
    
    XCTAssertNil([result objectForKey:@"_via_ua"]);
}


@end
