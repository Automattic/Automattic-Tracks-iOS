import SwiftUI

@available(iOS 14.0, OSX 11, *)
struct TracksEventDetailView: View {

    let event: ImmutableTracksEvent

    private let dateFormatter = DateFormatter()

    init(event: ImmutableTracksEvent) {
        self.event = event
        self.dateFormatter.dateStyle = .medium
        self.dateFormatter.timeStyle = .medium
    }

    var body: some View {
        #if os(macOS)
        List {
            content
        }
        #else
        Form {
            content
        }.navigationTitle("Event Details")
        #endif
    }

    var content: some View {
        Group {
            Section(header: Text("User Data")) {
                EventDetailRow(key: "Username", value: event.username)
                EventDetailRow(key: "User ID", value: event.userID)
                EventDetailRow(key: "User Agent", value: event.userAgent)
                EventDetailRow(key: "User Type", value: event.userType.stringValue)
            }

            Section(header: Text("User Properties")) {
                if event.userProperties.isEmpty{
                    Text("No User Properties Available")
                } else {
                    ForEach(event.userProperties) {
                        EventDetailRow($0)
                    }
                }
            }

            Section(header: Text("Device Properties")) {
                if event.deviceProperties.isEmpty {
                    Text("No Device Info Available")
                } else {
                    ForEach(event.deviceProperties) {
                        EventDetailRow($0)
                    }
                }
            }

            Section(header: Text("Event Data")) {
                EventDetailRow(key: "Event UUID", value: event.uuid.uuidString)
                EventDetailRow(key: "Event Name", value: event.name)
                EventDetailRow(key: "Event Date", value: dateFormatter.string(from: event.date))
            }

            Section(header: Text("Event Properties")) {
                if event.eventProperties.isEmpty {
                    Text("No Event Properties Available")
                } else {
                    ForEach(event.eventProperties) {
                        EventDetailRow($0)
                    }
                }
            }
        }
    }
}

@available(iOS 13.0, OSX 10.15, *)
struct EventDetailRow: View {
    let key: String
    let value: String

    init(key: String, value: String) {
        self.key = key
        self.value = value
    }

    init(_ keyValueType: KeyValueType<String>) {
        self.key = keyValueType.key
        self.value = keyValueType.value
    }

    var body: some View {
        #if os(macOS)
        HStack(alignment: .top) {
            Text(key).fontWeight(.bold)
            Text(value)
            Spacer()
        }
        #else
        VStack(alignment: .leading) {
            Text(key).font(.caption)
            Text(value)
        }
        #endif
    }
}
