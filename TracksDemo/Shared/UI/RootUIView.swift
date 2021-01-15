import SwiftUI
import AutomatticTracks

struct RootUIView: View {

    let tracksManager: TracksManager
    let logFileStorage: LogFileStorage

    init(tracksManager: TracksManager, logFileStorage: LogFileStorage) {
        self.tracksManager = tracksManager
        self.logFileStorage = logFileStorage
    }

    var body: some View {
        TabView {
            /// Tracks Events
            NavigationView {
                #if os(iOS)
                TracksEventCreationView(tracksManager: tracksManager)
                    .navigationTitle("Events")
                TracksEventListView(storage: tracksManager.tracksEventStorage)
                #elseif os(macOS)
                VStack {
                    TracksEventCreationView(tracksManager: tracksManager).padding()
                    TracksEventListView(storage: tracksManager.tracksEventStorage)
                }
                EmptyView(text: "Select a Tracks Event to get started")
                #endif
            }
            .tabItem {
                Image(systemName: "list.dash")
                Text("Events")
            }

            /// Encrypted Logs
            NavigationView {
                LogListView(logFileStorage: logFileStorage)
                    .navigationTitle("Encrypted Logs")
            }
            .tabItem {
                Image(systemName: "scroll")
                Text("Logs")
            }

            /// Crash Logs (Sentry)
            #if os(iOS)
            NavigationView {
                CrashLoggingView()
                    .navigationTitle("Crash Logging")

            }
            .tabItem {
                Image(systemName: "xmark.octagon")
                Text("Crashes")
            }
            #elseif os(macOS)
            CrashLoggingView()
            .padding()
            .tabItem {
                Image(systemName: "xmark.octagon")
                Text("Crashes")
            }
            #endif

            /// Settings
            #if os(iOS)
            NavigationView {
                SettingsView().navigationTitle("Settings")
            }
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            #elseif os(macOS)
            SettingsView()
            .padding()
            .tabItem {
                Image(systemName: "gearshape")
                Text("Settings")
            }
            #endif
        }
    }
}
