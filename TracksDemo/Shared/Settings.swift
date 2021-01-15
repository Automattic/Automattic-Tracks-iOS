import Foundation
import Combine
import AutomatticTracks

struct Settings {
    @UserDefault("wpcom-username", defaultValue: "")
    var username: String

    @UserDefault("wpcom-userid", defaultValue: "")
    var userId: String

    @UserDefault("wpcom-email-address", defaultValue: "")
    var email: String
}

extension Settings: TracksUserProvider {

    var tracksUser: TracksUser {
        TracksUser(userID: userId, email: email, username: username)
    }
}

class SettingsViewModel: ObservableObject {
    @Published
    var username: String {
        willSet { objectWillChange.send() }
        didSet { settings.username = username }
    }

    @Published
    var userId: String {
        willSet { objectWillChange.send() }
        didSet { settings.userId = userId }
    }

    @Published
    var email: String {
        willSet { objectWillChange.send() }
        didSet { settings.email = email }
    }

    private var settings: Settings

    init(settings: Settings) {
        self.settings = settings

        self.username = settings.username
        self.userId = settings.userId
        self.email = settings.email
    }
}
