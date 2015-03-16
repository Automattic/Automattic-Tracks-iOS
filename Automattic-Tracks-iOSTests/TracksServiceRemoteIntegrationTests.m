#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "TracksServiceRemote.h"

@interface TracksServiceRemoteIntegrationTests : XCTestCase

@property (nonatomic, strong) TracksServiceRemote *remote;

@end

@implementation TracksServiceRemoteIntegrationTests

- (void)setUp {
    [super setUp];

    self.remote = [[TracksServiceRemote alloc] init];
}

- (void)tearDown {
    [super tearDown];
    
    self.remote = nil;
}

- (void)testExample {
    TracksEvent *event = [TracksEvent new];
    event.eventName = @"wpios_test_event";
    
    __block XCTestExpectation *expectation = [self expectationWithDescription:@"test event"];
    
    [self.remote sendSingleTracksEvent:event completionHandler:^{
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:10.0 handler:nil];
}


@end
