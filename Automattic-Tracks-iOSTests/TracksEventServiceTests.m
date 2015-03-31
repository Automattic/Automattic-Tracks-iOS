#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TracksEventService.h"

@interface TracksEventServiceTests : XCTestCase

@property (nonatomic, strong) TracksEventService *subject;

@end

@implementation TracksEventServiceTests

- (void)setUp {
    [super setUp];

    self.subject = [[TracksEventService alloc] init];
}


- (void)tearDown {
    [super tearDown];
    
    self.subject = nil;
}


- (void)testTracksEventWithNilName {
    TracksEvent *event = [self.subject createTracksEventWithName:nil];
    
    XCTAssertNil(event);
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end
