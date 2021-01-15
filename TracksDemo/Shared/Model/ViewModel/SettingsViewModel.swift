import Foundation

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
