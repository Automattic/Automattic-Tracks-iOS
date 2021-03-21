import Foundation
import Combine

@available(iOS 13.0, OSX 10.15, *)
public class EventLoggingEmitter: ObservableObject {

    public enum UploadState {
        case uploading
        case paused(until: Date?)
        case cancelled
        case done
    }

    @Published
    var uploadState: UploadState = .paused(until: nil)

    let isUploadingPublisher = NotificationCenter.default.publisher(for: EventLogging.Notifications.didStartUploadNotification)
    let isPausedPublisher = NotificationCenter.default.publisher(for: EventLogging.Notifications.didPauseUploadNotification)
    let isCancelledPublisher = NotificationCenter.default.publisher(for: EventLogging.Notifications.didCancelUploadNotification)
    let isDonePublisher = NotificationCenter.default.publisher(for: EventLogging.Notifications.didFinishUploadNotification)

    private var cancellables = Set<AnyCancellable>()

    init() {
        isUploadingPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receivedUploadingNotification)
            .store(in: &cancellables)

        isPausedPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receivedPauseNotification)
            .store(in: &cancellables)

        isCancelledPublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receivedCancelNotification)
            .store(in: &cancellables)

        isDonePublisher
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: receivedUploadCompleteNotification)
            .store(in: &cancellables)
    }

    private func receivedUploadingNotification(_ notification: Notification) {
        self.uploadState = .uploading
    }

    private func receivedUploadCompleteNotification(_ notification: Notification) {
        self.uploadState = .done
    }

    private func receivedPauseNotification(_ notification: Notification) {
        self.uploadState = .paused(until: notification.object as? Date)
    }

    private func receivedCancelNotification(_ notification: Notification) {
        self.uploadState = .cancelled
    }
}
