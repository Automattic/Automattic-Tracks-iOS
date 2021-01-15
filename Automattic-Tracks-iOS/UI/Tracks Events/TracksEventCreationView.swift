import SwiftUI
import Combine

@available(iOS 14.0, OSX 11.0, *)
public struct TracksEventCreationView: View {

    @ObservedObject
    private var tracksEventStorage: TracksEventStorage

    private let tracksService: TracksService

    private var userDataSource: TracksUserProvider

    /// User ID State
    @State var selectionMode: TracksEventUserType = .anonymous

    /// Listens for and publishes events when Tracks starts and stops sending queued events
    private let willSendQueuedEvents = NotificationCenter.default.publisher(for: NSNotification.Name.TrackServiceWillSendQueuedEvents)
    private let didSendQueuedEvents = NotificationCenter.default.publisher(for: NSNotification.Name.TrackServiceDidSendQueuedEvents)

    @State var isSendingEvents: Bool = false

    public init(tracksManager: TracksManager) {
        self.tracksEventStorage = tracksManager.tracksEventStorage
        self.tracksService = tracksManager.tracksService
        self.userDataSource = tracksManager.userDataSource
    }

    public var body: some View {
        VStack(alignment: .leading) {
            Form {

                Picker(selection: $selectionMode, label: Text("")) {
                    Text("Anonymous").tag(TracksEventUserType.anonymous)
                    Text("WordPress.com").tag(TracksEventUserType.authenticated)
                }
                .onChange(of: selectionMode, perform: self.persistUserIdState)
                .pickerStyle(SegmentedPickerStyle())

                Section(header: Text("Create Events")) {
                    Button(action: self.sendTestEvent) {
                        Text("Create Default Event")
                    }

                    Button(action: self.sendTestEventWithProperties) {
                        Text("Create Event with Custom Properties")
                    }
                }

                Section(header: Text("Events Upload Queue")) {

                    #if os(iOS)
                    if tracksEventStorage.allEvents.isEmpty {
                        Text("No queued events")
                    } else {
                        NavigationLink("View \(tracksEventStorage.allEventsCount) Queued Events", destination: TracksEventListView(storage: tracksEventStorage))
                    }
                    #endif

                    Button(action: self.sendAllQueuedEvents) {
                        HStack {
                            Text("Upload \(tracksEventStorage.allEventsCount) Queued Events")
                            Spacer()

                            if isSendingEvents {
                                ProgressView()
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            /// By default when the app becomes active, the events fire. We'll override that here to avoid this
            tracksService.remoteCallsEnabled = false
        }
        .onReceive(willSendQueuedEvents) { _ in
            isSendingEvents = true
            tracksService.remoteCallsEnabled = false
        }
        .onReceive(didSendQueuedEvents) { _ in
            isSendingEvents = false
            tracksService.remoteCallsEnabled = false
        }
    }
}

@available(iOS 14.0, OSX 11.0, *)
extension TracksEventCreationView {
    private func sendTestEvent() {
        tracksService.trackEventName("test_event")
    }

    private func sendTestEventWithProperties() {
        tracksService.trackEventName("test_event_with_properties", withCustomProperties: [
            "custom_prop_1": "valuetew",
        ])
    }

    private func persistUserIdState(newValue: TracksEventUserType) {
        switch newValue {
            case .anonymous:
                tracksService.switchToAnonymousUser(withAnonymousID: UUID().uuidString)
            case .authenticated:

                tracksService.switchToAuthenticatedUser(
                    withUsername: userDataSource.tracksUser.username,
                    userID: userDataSource.tracksUser.userID,
                    skipAliasEventCreation: true
                )
            @unknown default:
                preconditionFailure("Tracks Event User Type not handled")
        }
    }

    private func sendAllQueuedEvents() {
        tracksService.sendQueuedEvents()
    }
}
