#import "ViewController.h"
#import <TracksService.h>

@interface ViewController () <NSFetchedResultsControllerDelegate>

@property (nonatomic, strong) TracksService *tracksService;
@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;

@property (nonatomic, weak) IBOutlet UILabel *objectCountLabel;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.tracksService = [[TracksService alloc] init];
    self.tracksService.queueSendInterval = 10.0;
    
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES];
    fetchRequest.sortDescriptors = @[sortDescriptor];
    self.fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                        managedObjectContext:self.tracksService.contextManager.managedObjectContext
                                                                          sectionNameKeyPath:nil
                                                                                   cacheName:nil];
    self.fetchedResultsController.delegate = self;
    [self.fetchedResultsController performFetch:nil];
    [self updateObjectCountLabel];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - IBAction methods

- (IBAction)sendTestEvent:(id)sender
{
    [self.tracksService trackEventName:@"test_event"];
}


- (IBAction)crashApplicationTapped:(id)sender
{
    abort();
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

@end
