import Foundation
import CommonCrypto
import Sodium

public class EventLogging {

    /// Add a Log File to the list of events that need to be uploaded
    public func enqueueLogForUpload(log: LogFile) throws {
        try uploadQueue.add(log)

        /// Notify observers of a new log in the queue
        delegate.didQueueLogForUpload(log)

        /// Restart the automatic upload queue when log files are added
        uploadNextLogFileIfNeeded()
    }

    /// Maintains a list of events that need to be uploaded
    private let uploadQueue: EventLoggingUploadQueue

    /// Coordinates one-at-a-time file log dequeuing and upload
    private let lock = NSLock()
    private let processingQueue = DispatchQueue(label: "event-logging-upload")

    /// Uploads Events
    private let uploadManager: EventLoggingUploadManager

    /// Data Source
    let dataSource: EventLoggingDataSource

    /// Delegate
    let delegate: EventLoggingDelegate

    public init(dataSource: EventLoggingDataSource,
                delegate: EventLoggingDelegate,
                fileManager: FileManager = FileManager.default
    ) {
        self.dataSource = dataSource
        self.delegate = delegate

        self.uploadManager = EventLoggingUploadManager(dataSource: dataSource, delegate: delegate)

        self.uploadQueue = EventLoggingUploadQueue(
            storageDirectory: dataSource.logUploadQueueStorageURL,
            fileManager: fileManager
        )

        /// Start taking items off the queue and uploading them if needed
        uploadNextLogFileIfNeeded()
    }

    /// Schedule encryption and upload for the next log file in the queue
    public func uploadNextLogFileIfNeeded() {
        DispatchQueue.global(qos: .background).async(execute: runUploadLogs)
    }

    /// Current enqueued log files
    public var queuedLogFiles: [LogFile] {
        return uploadQueue.items
    }

    /// Support adding additional time between requests if they are failing – reset after an hour to match the server
    private var exponentialBackoffTimer = ExponentialBackoffTimer(minimumDelay: 2, maximumDelay: 3600)

    /// The date that uploads will automatically resume after being paused due to failure
    public var uploadsPausedUntil: Date? {
        guard exponentialBackoffTimer.nextDate.compare(Date()) == .orderedDescending else {
            return nil
        }

        return exponentialBackoffTimer.nextDate
    }
}




extension EventLogging {

    /// Start uploading the next log if the queue, if possible.
    /// This method shouldn't be called directly – it should be dispatched via `uploadNextLogFileIfNeeded`
    private func runUploadLogs() {
        /// Ensure that only one instance of this method is running at the same time
        guard lock.try() else {
            return
        }

        /// If the queue is empty, just bail without rescheduling – the next item added to the queue will start the process up again
        guard let log = uploadQueue.first else {
            lock.unlock()
            return
        }

        /// If the backoff timer is blocking execution, reschedule the next run
        guard exponentialBackoffTimer.next < .now() else {
            retryUploadsAt(exponentialBackoffTimer.next)
            lock.unlock()
            return
        }

        /// If the delegate is reporting that we shouldn't upload log files, pause upload to prevent an endless loop
        guard delegate.shouldUploadLogFiles else {
            delegate.uploadCancelledByDelegate(log)
            retryUploadsAt(.distantFuture)
            lock.unlock()
            return
        }

        let dispatchGroup = DispatchGroup()
        dispatchGroup.enter()

        processingQueue.async {
            do {
                let encryptedLog = try self.encryptLog(log)

                /// Upload the log
                self.uploadManager.upload(encryptedLog) { result in
                    if case .success = result {
                        try? self.uploadQueue.remove(log)

                        /// Reset the timer if requests are succeeding
                        self.exponentialBackoffTimer.reset()
                    }
                    else {
                        /// Wait longer between requests if they are failing
                        self.exponentialBackoffTimer.increment()
                        self.retryUploadsAt(self.exponentialBackoffTimer.next)
                    }

                    dispatchGroup.leave()
                }
            }
            catch let err {
                /// This is almost certainly a file error – encryption errors would assert and crash the app. This includes situations like:
                /// - the device is out of storage space
                /// - the file was deleted while we were reading it
                /// - the file (or device storage system) is corrupt
                /// Because this should be extremely rare (and is difficult to reproduce), we'll track it but it's not covered by a test case

                self.delegate.logError(err, userInfo: [
                    "errorFile": #file,
                    "errorLine": #line,
                    "logFileUUID": log.uuid
                ])

                dispatchGroup.leave()
            }
        }

        dispatchGroup.wait()

        /// When we're done, attempt to upload the next log file
        DispatchQueue.global(qos: .background).async {
            /// Manually release the lock before trying again – this prevents a race condition where
            /// the next thread could start reading too early if `defer` was used.
            self.lock.unlock()

            self.uploadNextLogFileIfNeeded()
        }
    }

    // Provides an easier-to-understand way to call `uploadNextLogFileIfNeeded` at the designated time
    private func retryUploadsAt(_ time: DispatchTime) {
        DispatchQueue.global(qos: .background).asyncAfter(deadline: time, execute: uploadNextLogFileIfNeeded)
    }

    // Extracted for readability
    private func encryptLog(_ log: LogFile) throws -> LogFile {
        let encryptionKey = Data(base64Encoded: dataSource.loggingEncryptionKey)
        precondition(encryptionKey != nil, "The encryption key is not a valid base64 encoded string")
        let key = Bytes(encryptionKey!)

        let encryptedURL = try LogEncryptor(withPublicKey: key).encryptLog(log)
        return LogFile(url: encryptedURL, uuid: log.uuid)
    }
}
