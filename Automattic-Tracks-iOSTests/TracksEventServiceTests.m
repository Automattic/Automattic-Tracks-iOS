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
    TracksEvent *event = [self.subject createTracksEventWithName:nil username:@"someone" userAgent:nil userType:TracksEventUserTypeWordPressCom eventDate:[NSDate date]];
    
    XCTAssertNil(event);
}

@end
