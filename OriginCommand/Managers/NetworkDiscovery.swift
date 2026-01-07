import Foundation
import Network

/// mDNS/Bonjour network discovery for audio streaming devices
actor NetworkDiscovery {
    private var browser: NWBrowser?
    private var discoveredEndpoints: [NWEndpoint: DeviceType] = [:]
    
    /// Service types to scan for
    private let serviceTypes: [(type: String, deviceType: DeviceType)] = [
        ("_linkplay._tcp", .wiim),
        // ("_musc._tcp", .bluesound) // Add when BluOS API is documented
    ]
    
    /// Start discovering devices on the network
    func startDiscovery() -> AsyncStream<DiscoveryEvent> {
        AsyncStream { continuation in
            Task {
                await self.setupBrowsers(continuation: continuation)
            }
        }
    }
    
    /// Stop all discovery
    func stopDiscovery() {
        browser?.cancel()
        browser = nil
        discoveredEndpoints.removeAll()
    }
    
    private func setupBrowsers(continuation: AsyncStream<DiscoveryEvent>.Continuation) {
        // For MVP, just scan for Linkplay devices
        let descriptor = NWBrowser.Descriptor.bonjour(type: "_linkplay._tcp", domain: "local.")
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: descriptor, using: parameters)
        self.browser = browser
        
        browser.stateUpdateHandler = { state in
            switch state {
            case .ready:
                print("[Discovery] Browser ready")
            case .failed(let error):
                print("[Discovery] Browser failed: \(error)")
                continuation.yield(.error(error))
            case .cancelled:
                print("[Discovery] Browser cancelled")
                continuation.finish()
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { results, changes in
            for change in changes {
                switch change {
                case .added(let result):
                    Task {
                        await self.handleEndpointAdded(result, deviceType: .wiim, continuation: continuation)
                    }
                case .removed(let result):
                    Task {
                        await self.handleEndpointRemoved(result, continuation: continuation)
                    }
                default:
                    break
                }
            }
        }
        
        browser.start(queue: .main)
    }
    
    private func handleEndpointAdded(
        _ result: NWBrowser.Result,
        deviceType: DeviceType,
        continuation: AsyncStream<DiscoveryEvent>.Continuation
    ) {
        discoveredEndpoints[result.endpoint] = deviceType
        
        // Resolve the endpoint to get IP address
        let connection = NWConnection(to: result.endpoint, using: .tcp)
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                if let innerEndpoint = connection.currentPath?.remoteEndpoint,
                   case .hostPort(let host, let port) = innerEndpoint {
                    let ipAddress: String
                    switch host {
                    case .ipv4(let addr):
                        ipAddress = "\(addr)"
                    case .ipv6(let addr):
                        ipAddress = "\(addr)"
                    case .name(let name, _):
                        ipAddress = name
                    @unknown default:
                        ipAddress = "unknown"
                    }
                    
                    // Extract name from endpoint metadata
                    var deviceName = "Unknown Device"
                    if case .service(let name, _, _, _) = result.endpoint {
                        deviceName = name
                    }
                    
                    continuation.yield(.deviceFound(
                        name: deviceName,
                        ipAddress: ipAddress,
                        port: Int(port.rawValue),
                        type: deviceType
                    ))
                }
                connection.cancel()
            case .failed:
                connection.cancel()
            default:
                break
            }
        }
        connection.start(queue: .main)
    }
    
    private func handleEndpointRemoved(
        _ result: NWBrowser.Result,
        continuation: AsyncStream<DiscoveryEvent>.Continuation
    ) {
        discoveredEndpoints.removeValue(forKey: result.endpoint)
        
        if case .service(let name, _, _, _) = result.endpoint {
            continuation.yield(.deviceLost(name: name))
        }
    }
}

/// Events from network discovery
enum DiscoveryEvent {
    case deviceFound(name: String, ipAddress: String, port: Int, type: DeviceType)
    case deviceLost(name: String)
    case error(Error)
}
