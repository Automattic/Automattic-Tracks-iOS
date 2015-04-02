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
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)sendTestEvent:(id)sender
{
    [self.tracksService trackEventName:@"test_event"];
}


#pragma mark - Fetched results delegate methods

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath;
{
    self.objectCountLabel.text = [NSString stringWithFormat:@"Number of events queued: %@", @(self.fetchedResultsController.fetchedObjects.count)];
}

@end
