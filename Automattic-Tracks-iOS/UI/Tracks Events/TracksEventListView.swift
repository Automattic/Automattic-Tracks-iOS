import SwiftUI

@available(OSX 10.12, *)
private let dateFormatter = ISO8601DateFormatter()

@available(iOS 14.0, OSX 11.0, *)
public struct TracksEventListView: View {


    @ObservedObject
    private var storage: TracksEventStorage

    public init(storage: TracksEventStorage) {
        self.storage = storage
    }

    public var body: some View {
        Group {
            if storage.allEventsCount == 0 {
                EmptyView(text: "No Events")
            } else {
                List(storage.allEvents) { event in
                    NavigationLink(destination: TracksEventDetailView(event: event)) {
                        TracksEventListRow(event: event)
                    }
                }
            }
        }.navigationTitle("Queued Events")
    }
}

@available(iOS 14.0, OSX 11.0, *)
public struct TracksEventListRow: View {
    let event: ImmutableTracksEvent

    public var body: some View {
        VStack(alignment: .leading) {
            Text(event.name)
            Text(dateFormatter.string(from: event.date))
                .font(.caption)

            HStack {
                TagView(text: event.userType.displayStringValue, color: event.userType.displayColor)

                if !event.userProperties.isEmpty {
                    TagView(text: "Has User Properties", color: .purple)
                }

                if !event.eventProperties.isEmpty {
                    TagView(text: "Has Event Properties", color: .green)
                }

                if !event.deviceProperties.isEmpty {
                    TagView(text: "Has Device Properties", color: .purple)
                }
            }
        }
    }
}

@available(iOS 14.0, OSX 11.0, *)
public struct TagView: View {
    let text: String
    let color: Color

    public var body: some View {

        Text(text)
            .font(.caption2)
            .padding(EdgeInsets(top: 3, leading: 8, bottom: 3, trailing: 8))
            .foregroundColor(.white)
            .background(RoundedRectangle(cornerRadius: 6, style: .circular).foregroundColor(color))
            .lineLimit(1)
    }
}

@available(iOS 14.0, OSX 11.0, *)
extension TracksEventUserType {
    var displayStringValue: String {
        let capitalizedFirstLetter = stringValue.prefix(1).capitalized
        return String(capitalizedFirstLetter + stringValue.dropFirst())
    }

    var displayColor: Color {
        switch self {
            case .anonymous: return .orange
            case .authenticated: return .blue
            @unknown default: return .red
        }
    }
}
