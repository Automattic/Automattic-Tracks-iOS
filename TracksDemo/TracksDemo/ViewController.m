#import "ViewController.h"
#import <TracksEventService.h>
#import <TracksService.h>

@interface ViewController ()

@property (nonatomic, strong) TracksEventService *tracksEventService;
@property (nonatomic, strong) TracksService *tracksService;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tracksEventService = [[TracksEventService alloc] init];
    self.tracksService = [[TracksService alloc] init];
    self.tracksService.queueSendInterval = 1.0;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)sendTestEvent:(id)sender
{
    TracksEvent *tracksEvent = [self.tracksEventService createTracksEventWithName:@"test_event"];
    [self.tracksService trackEvent:tracksEvent];
}

@end
