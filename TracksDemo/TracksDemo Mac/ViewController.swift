//
//  ViewController.swift
//  TracksDemo Mac
//
//  Created by Jeremy Massel on 2019-01-04.
//  Copyright © 2019 Automattic Inc. All rights reserved.
//

import Cocoa
import AutomatticTracks

class ViewController: NSViewController {

    private lazy var contextManager = TracksContextManager()
    private lazy var tracksService = TracksService(contextManager: contextManager)
    private var fetchedResultsController: NSFetchedResultsController<TracksEventCoreData>!

    @IBOutlet var progressView: NSProgressIndicator!
    @IBOutlet weak var queuedEventsLabel: NSTextField!
    
    var sendInterval: TimeInterval {
        get{ return tracksService?.queueSendInterval ?? 10 }
        set { tracksService?.queueSendInterval = newValue}
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        tracksService?.queueSendInterval = 10.0
        tracksService?.eventNamePrefix = "tracks_macos_demo"

        resetTimer()
        setupFetchedResultsController()
        addTimerEventListeners()
        switchToAnonymousUser()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    //MARK: - IB Action Methods
    @IBAction func didClickTrackEvent(_ sender: NSButton) {
        tracksService?.trackEventName("test_event")
    }

    @IBAction func didClickTrackEventWithCustomProperties(_ sender: NSButton) {
        tracksService?.trackEventName("test_event_with_properties", withCustomProperties: [
            "custom_prop_1": "valuetew"
        ])
    }

    @IBAction func didClickCrashApplication(_ sender: NSButton ) {
        abort()
    }

    @IBAction func userTypeSegmentedControlDidChange(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            switchToAnonymousUser()
        }
        else {
            switchToWordPressDotComUser()
        }
    }

    @IBAction func automaticallySendEventsToggled(_ sender: NSButton) {
        tracksService?.remoteCallsEnabled = sender.state == .on

        if sender.state == .on {
            resetTimer()
        }
        else{
            timer.invalidate()
        }
    }

    //MARK: – Fetched Results Controller
    private func setupFetchedResultsController(){
        let fetchRequest = NSFetchRequest<TracksEventCoreData>(entityName: "TracksEvent")
        fetchRequest.sortDescriptors = [ NSSortDescriptor(key: "date", ascending: true) ]

        self.fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: contextManager.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil)

        self.fetchedResultsController.delegate = self

        do{
            try self.fetchedResultsController.performFetch()
        }
        catch let err {
            debugPrint("Error fetching Tracks Events: \(err.localizedDescription)")
        }
    }

    //MARK: - Timer
    private lazy var timer = Timer()
    private var startTime: Date!

    private func addTimerEventListeners() {
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimer), name: NSNotification.Name.TrackServiceWillSendQueuedEvents, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(resetTimer), name: NSNotification.Name.TrackServiceDidSendQueuedEvents, object: nil)
    }

    @objc private func resetTimer() {
        timer.invalidate()
        startTime = Date()
        progressView.doubleValue = 0

        timer = Timer.scheduledTimer(timeInterval: sendInterval / 100, target: self, selector: #selector(fireTimer(_:)), userInfo: nil, repeats: true)
    }

    @objc func fireTimer(_ sender: Timer) {
        if sender.fireDate.timeIntervalSince(startTime) > sendInterval {
            timer.invalidate()
        }

        let progress = sender.fireDate.timeIntervalSince(startTime) / sendInterval
        progressView.doubleValue = progress * 100
    }

    //MARK: - Helpers
    private func updateObjectCountLabel() {
        let count = fetchedResultsController.fetchedObjects?.count ?? 0
        queuedEventsLabel.stringValue = "Number of events queued: \(count)"
    }

    private func switchToAnonymousUser() {
        tracksService?.switchToAnonymousUser(withAnonymousID: NSUUID().uuidString)
    }

    private func switchToWordPressDotComUser() {
        tracksService?.switchToAuthenticatedUser(withUsername: "astralbodies", userID: "67137", skipAliasEventCreation: false)
    }
}

extension ViewController: NSFetchedResultsControllerDelegate {
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        self.updateObjectCountLabel()
    }
}
