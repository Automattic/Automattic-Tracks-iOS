import SwiftUI
import AutomatticTracks

struct SettingsView: View {

    @ObservedObject
    private var viewModel: SettingsViewModel

    init(settings: Settings = Settings()) {
        self.viewModel = SettingsViewModel(settings: settings)
    }

    var body: some View {
        Form {
            Section(header: Text("WordPress.com User Data")) {
                HStack {
                    Text("Username:").fontWeight(.bold)
                    #if os(macOS)
                    TextField("Username", text: $viewModel.username)
                    #else
                    TextField("Username", text: $viewModel.username)
                        .autocapitalization(.none)
                    #endif
                }
                HStack {
                    Text("Email:").fontWeight(.bold)
                    #if os(macOS)
                    TextField("Email Address", text: $viewModel.email)
                    #else
                    TextField("Email Address", text: $viewModel.email)
                        .keyboardType(.emailAddress)
                        .autocapitalization(.none)
                    #endif
                }
                HStack {
                    Text("User ID:").fontWeight(.bold)
                    #if os(macOS)
                    TextField("User ID", text: $viewModel.userId)
                    #else
                    TextField("User ID", text: $viewModel.userId)
                        .keyboardType(.numberPad)
                    #endif

                }
            }

            #if os(macOS)
            /// Push the form up to the top of the screen
            Spacer()
            #endif
        }
    }
}
