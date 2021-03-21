import Foundation
import AutomatticTracks

/// An NSUserDefaults backed settings store for the Demo App
struct Settings {
    @UserDefault("wpcom-username", defaultValue: "")
    var username: String

    @UserDefault("wpcom-userid", defaultValue: "")
    var userId: String

    @UserDefault("wpcom-email-address", defaultValue: "")
    var email: String
}

/// Allow Settings to be used as a `TracksUserProvider` for use in `TracksManager`
extension Settings: TracksUserProvider {

    var tracksUser: TracksUser {
        TracksUser(userID: userId, email: email, username: username)
    }
}
