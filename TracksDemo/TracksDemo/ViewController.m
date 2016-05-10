#import "ViewController.h"
@import AutomatticTracks;

@interface ViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksService *tracksService;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;
@property (nonatomic, weak) IBOutlet UILabel *objectCountLabel;
@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, strong) NSDate *startTime;

@property (nonatomic, weak) IBOutlet UISwitch *remoteCallsSwitch;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.contextManager = [TracksContextManager new];
    self.tracksService = [[TracksService alloc] initWithContextManager:self.contextManager];
    self.tracksService.queueSendInterval = 10.0;
    [self resetTimer];
    
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.contextManager.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
    [self updateObjectCountLabel];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTimer) name:TrackServiceWillSendQueuedEventsNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetTimer) name:TrackServiceDidSendQueuedEventsNotification object:nil];
    
    [self switchToAnonymousUser];
}


- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


#pragma mark - IBAction methods

- (IBAction)sendTestEvent:(id)sender
{
    [self.tracksService trackEventName:@"test_event"];
}


- (IBAction)sendTestEventWithProperties:(id)sender
{
    [self.tracksService trackEventName:@"test_event_with_properties" withCustomProperties:@{@"custom_prop_1" : @"valuetew"}];
}


- (IBAction)crashApplicationTapped:(id)sender
{
    abort();
}


- (IBAction)userTypeSegmentedControlChanged:(UISegmentedControl *)sender
{
    if (sender.selectedSegmentIndex == 0) {
        [self switchToAnonymousUser];
    } else {
        [self switchToWordPressComUser];
    }
}


- (IBAction)remoteCallsSwitchTapped:(UISwitch *)sender
{
    self.tracksService.remoteCallsEnabled = sender.isOn;
    
    if (sender.isOn) {
        [self resetTimer];
    } else {
        [self.timer invalidate];
    }
}


#pragma mark - Fetched results delegate methods

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;
{
    [self updateObjectCountLabel];
}


#pragma mark - Private helper methods

- (void)updateObjectCountLabel
{
    self.objectCountLabel.text = [NSString stringWithFormat:@"Number of events queued: %@", @(self.fetchedResultsController.fetchedObjects.count)];
}

- (void)resetTimer
{
    [self.timer invalidate];
    self.startTime = [NSDate date];
    self.progressView.progress = 0.0f;
    
    self.timer = [NSTimer scheduledTimerWithTimeInterval:self.tracksService.queueSendInterval / 100
                                                  target:self
                                                selector:@selector(timerFireMethod:)
                                                userInfo:nil
                                                 repeats:YES];
}


- (void)timerFireMethod:(NSTimer *)timer
{
    NSDate *fireDate = timer.fireDate;
    
    if ([fireDate timeIntervalSinceDate:self.startTime] > self.tracksService.queueSendInterval) {
        [self.timer invalidate];
    }
    
    CGFloat progress = [fireDate timeIntervalSinceDate:self.startTime] / self.tracksService.queueSendInterval;
    self.progressView.progress = progress;
}


- (void)switchToAnonymousUser
{
    [self.tracksService switchToAnonymousUserWithAnonymousID:[[NSUUID UUID] UUIDString]];
}


- (void)switchToWordPressComUser
{
    [self.tracksService switchToAuthenticatedUserWithUsername:@"astralbodies" userID:@"67137" skipAliasEventCreation:NO];
}

@end
