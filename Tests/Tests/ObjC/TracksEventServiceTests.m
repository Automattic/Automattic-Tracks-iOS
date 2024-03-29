#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

#if SWIFT_PACKAGE
@import AutomatticTracksEvents;
#else
#import "TracksEventService.h"
#import "TracksEventPersistenceService.h"
#endif

@interface TracksEventServiceTests : XCTestCase

@property (nonatomic, strong) TracksEventService *subject;
@property (nonatomic, strong) TracksEventPersistenceService *eventPersistenceMock;

@end

@implementation TracksEventServiceTests

- (void)setUp {
    [super setUp];

    self.subject = [[TracksEventService alloc] initWithContextManager:nil];
    self.eventPersistenceMock = OCMClassMock([TracksEventPersistenceService class]);
    self.subject.persistenceService = self.eventPersistenceMock;
}


- (void)tearDown {
    [super tearDown];
    
    self.subject = nil;
    self.eventPersistenceMock = nil;
}


- (void)testTracksEventWithNilName {
    OCMStub([self.eventPersistenceMock persistTracksEvent:[OCMArg isNotNil]]);
    
    TracksEvent *event = [self.subject createTracksEventWithName:nil
                                                        username:@"someone"
                                                          userID:@"MOOP"
                                                       userAgent:nil
                                                        userType:TracksEventUserTypeAuthenticated
                                                       eventDate:[NSDate date]
                                                customProperties:nil
                                                deviceProperties:nil
                                                  userProperties:nil];

    XCTAssertNil(event);
    OCMVerifyAll((id)self.eventPersistenceMock);
}

- (void)testCreateTracksEventForAliasingWordPressComUserValidData
{
    OCMExpect([self.eventPersistenceMock persistTracksEvent:[OCMArg isNotNil]]);
    
    TracksEvent *event = [self.subject createTracksEventForAliasingWordPressComUser:@"wordpress" userID:@"12345" withAnonymousUserID:@"anon123"];
    
    OCMVerifyAll((id)self.eventPersistenceMock);
    XCTAssertNotNil(event);
    XCTAssertEqual(@"wordpress", event.username);
    XCTAssertEqual(@"12345", event.userID);
    XCTAssertEqual(1, event.customProperties.count);
    XCTAssertEqual(@"anon123", event.customProperties[@"anonId"]);
    XCTAssertEqual(0, event.deviceProperties.count);
    XCTAssertEqual(0, event.userProperties.count);
}


@end
