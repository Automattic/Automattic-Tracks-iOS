import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = TracksViewModel()

    var body: some View {
        VStack {
            Picker("User Type", selection: $viewModel.userType) {
                Text("Anonymous").tag(0)
                Text("WordPress").tag(1)
            }

            Toggle("Automatically Send Events", isOn: $viewModel.automaticallySendEvents)
            
            Button("Track Event") {
                viewModel.trackEvent()
            }
            Button("Track Event With Properties") {
                viewModel.trackEventWithCustomProperties()
            }
            Button("Crash Application") {
                viewModel.crashApplication()
            }
            ProgressView(value: viewModel.progress, total: 1.0)
            Text(viewModel.queuedEventsLabel)
        }
        .padding()
        .onAppear() {
            viewModel.load()
        }
    }
}

#Preview {
    ContentView()
}
