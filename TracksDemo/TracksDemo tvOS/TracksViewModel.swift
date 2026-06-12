import Foundation
import AutomatticTracks
import Combine

class TracksViewModel: NSObject, ObservableObject {

    private lazy var contextManager = TracksContextManager()
    private lazy var tracksService = TracksService(contextManager: contextManager)
    private var fetchedResultsController: NSFetchedResultsController<TracksEventCoreData>!

    @Published var progress: Double = 0.5
    @Published var queuedEventsLabel: String = ""

    var sendInterval: TimeInterval {
        get { return tracksService?.queueSendInterval ?? 10 }
        set { tracksService?.queueSendInterval = newValue}
    }

    func load() {
        // Do any additional setup after loading the view.
        tracksService?.queueSendInterval = 10.0
        tracksService?.eventNamePrefix = "tracks_tvos_demo"

        resetTimer()
        setupFetchedResultsController()
        addTimerEventListeners()
        switchToAnonymousUser()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func trackEvent() {
        tracksService?.trackEventName("test_event")
    }

    func trackEventWithCustomProperties() {
        tracksService?.trackEventName("test_event_with_properties", withCustomProperties: [
            "custom_prop_1": "valuetew"
        ])
    }

    func crashApplication() {
        abort()
    }

    @Published var userType: Int = 0 {
        didSet {
            if userType == 0 {
                switchToAnonymousUser()
            }
            else {
                switchToWordPressDotComUser()
            }
        }
    }

    @Published var automaticallySendEvents: Bool = true {
        didSet {
            tracksService?.remoteCallsEnabled = automaticallySendEvents

            if automaticallySendEvents {
                resetTimer()
            } else {
                timer.invalidate()
            }
        }
    }

    // MARK: – Fetched Results Controller
    private func setupFetchedResultsController() {
        let fetchRequest = NSFetchRequest<TracksEventCoreData>(entityName: "TracksEvent")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]

        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: contextManager.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        self.fetchedResultsController.delegate = self

        do {
            try self.fetchedResultsController.performFetch()
        }
        catch let err {
            debugPrint("Error fetching Tracks Events: \(err.localizedDescription)")
        }
    }

    // MARK: - Timer
    private lazy var timer = Timer()
    private var startTime: Date!

    private func addTimerEventListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimer), name: NSNotification.Name.TrackServiceWillSendQueuedEvents, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimer), name: NSNotification.Name.TrackServiceDidSendQueuedEvents, object: nil)
    }

    @objc private func resetTimer() {
        timer.invalidate()
        startTime = Date()
        progress = 0

        timer = Timer.scheduledTimer(timeInterval: sendInterval / 100, target: self, selector: #selector(fireTimer(_:)), userInfo: nil, repeats: true)
    }

    @objc func fireTimer(_ sender: Timer) {
        if sender.fireDate.timeIntervalSince(startTime) > sendInterval {
            timer.invalidate()
        }

        let progress = max(0, min(sender.fireDate.timeIntervalSince(startTime) / sendInterval, 1.0))
        self.progress = progress
    }

    // MARK: - Helpers
    private func updateObjectCountLabel() {
        DispatchQueue.main.async { [weak self] in
            let count = self?.fetchedResultsController.fetchedObjects?.count ?? 0
            self?.queuedEventsLabel = "Number of events queued: \(count)"
        }
    }

    private func switchToAnonymousUser() {
        tracksService?.switchToAnonymousUser(withAnonymousID: NSUUID().uuidString)
    }

    private func switchToWordPressDotComUser() {
        tracksService?.switchToAuthenticatedUser(withUsername: "astralbodies", userID: "67137", skipAliasEventCreation: false)
    }
}

extension TracksViewModel: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        self.updateObjectCountLabel()
    }
}
