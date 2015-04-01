#import "ViewController.h"
#import <TracksService.h>

@interface ViewController ()

@property (nonatomic, strong) TracksService *tracksService;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tracksService = [[TracksService alloc] init];
    self.tracksService.queueSendInterval = 10.0;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)sendTestEvent:(id)sender
{
    [self.tracksService trackEventName:@"test_event"];
}

@end
