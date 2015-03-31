#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TracksService.h"
#import <OCMock/OCMock.h>

@interface TrackServiceTests : XCTestCase

@property (nonatomic, strong) TracksService *subject;

@end

@implementation TrackServiceTests

- (void)setUp {
    [super setUp];

    self.subject = [[TracksService alloc] init];
    self.subject.remote = OCMClassMock([TracksServiceRemote class]);
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
    [self.subject trackEventName:@"Test"];
    
    XCTAssertEqual(1, self.subject.queuedEventCount);
}


- (void)testSendQueuedEventsOneEvent
{
    [self.subject trackEventName:@"Test"];
    
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
