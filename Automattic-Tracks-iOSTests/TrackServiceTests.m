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
    TracksEvent *event = [TracksEvent new];
    event.eventName = @"Test";
    
    [self.subject trackEvent:event];
    
    XCTAssertEqual(1, self.subject.queuedEventCount);
}


- (void)testSendQueuedEventsOneEvent
{
    TracksEvent *event = [TracksEvent new];
    event.eventName = @"Test";
    
    [self.subject trackEvent:event];
    
    OCMExpect([self.subject.remote sendBatchOfEvents:[OCMArg checkWithBlock:^BOOL(id obj) {
        XCTAssertTrue([obj isKindOfClass:[NSArray class]]);
        
        return ([obj count] == 1);
    }]
                              withSharedProperties:[OCMArg isNotNil]
                                 completionHandler:[OCMArg isNotNil]]);

    [self.subject sendQueuedEvents];
    
    OCMVerifyAll((id)self.subject.remote);
}


- (void)testSendQueuedEventsNoEvents
{
    [self.subject sendQueuedEvents];
    
    OCMVerifyAll((id)self.subject.remote);
}

@end
