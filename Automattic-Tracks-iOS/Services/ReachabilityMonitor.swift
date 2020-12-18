import Foundation
import Network

@objc
@available(OSX 10.14, *)
class ReachabilityMonitor: NSObject {

    private let monitor = NWPathMonitor()

    private let internalQueue = DispatchQueue(label: "tracks-reachability-monitor")

    @objc
    var isReachable: Bool {
        monitor.currentPath.status == .satisfied
    }

    @objc
    var isTethering: Bool {
        monitor.currentPath.isExpensive
    }

    @objc
    var isConnectedViaWifi: Bool {
        monitor.currentPath.usesInterfaceType(.wifi)
    }

    @objc
    var isConnectedViaCellular: Bool {
        monitor.currentPath.usesInterfaceType(.cellular)
    }

    @objc
    var isConnectedViaEthernet: Bool {
        monitor.currentPath.usesInterfaceType(.wiredEthernet)
    }

    override init() {
        super.init()
        monitor.pathUpdateHandler = handlePathUpdate
    }

    @objc
    func startMonitoring() {
        monitor.start(queue: internalQueue)
    }

    @objc
    func stopMonitoring() {
        monitor.cancel()
    }

    typealias ReachabilityListener = (ReachabilityMonitor) -> Void

    private func handlePathUpdate(_ path: NWPath) {
        /// Notify all listeners that reachability may have changed
        listeners.forEach { $0(self) }
    }

    private var listeners = [ReachabilityListener]()

    @objc
    func addListener(_ listener: @escaping ReachabilityListener) {
        listeners.append(listener)
    }

    @available(iOS 13.0, OSX 10.15, *)
    func getIsUsingLowDataMode() -> Bool {
        monitor.currentPath.isConstrained
    }
}
