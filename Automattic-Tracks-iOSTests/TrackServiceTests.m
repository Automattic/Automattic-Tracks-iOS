#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TracksService.h"
#import <OCMock/OCMock.h>

@interface TrackServiceTests : XCTestCase

@property (nonatomic, strong) TracksService *subject;
@property (nonatomic, strong) TracksServiceRemote *tracksServiceRemote;
@property (nonatomic, strong) TracksEventService *tracksEventService;

@end

@implementation TrackServiceTests

- (void)setUp {
    [super setUp];

    self.subject = [[TracksService alloc] init];
    self.tracksServiceRemote = OCMClassMock([TracksServiceRemote class]);
    self.tracksEventService = OCMClassMock([TracksEventService class]);
    
    self.subject.tracksEventService = self.tracksEventService;
    self.subject.remote = self.tracksServiceRemote;
}


- (void)tearDown {
    [super tearDown];
    
    self.subject = nil;
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
    OCMStub([self.tracksEventService createTracksEventWithName:@"wpios_Test"
                                                      username:[OCMArg isNotNil]
                                                        userID:[OCMArg isNotNil]
                                                     userAgent:[OCMArg isNil]
                                                      userType:TracksEventUserTypeAnonymous
                                                     eventDate:[OCMArg isNotNil]
                                              customProperties:[OCMArg isNotNil]
                                              deviceProperties:[OCMArg isNotNil]
                                                userProperties:[OCMArg isNotNil]])
    .andReturn(tracksEvent);
    
    [self.subject trackEventName:@"Test"];
    
    OCMVerifyAll((id)self.tracksEventService);
}


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
                                 completionHandler:[OCMArg checkWithBlock:^BOOL(void (^passedBlock)()) {
        passedBlock();
        
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

@end
