import Foundation
import SwiftUI

/// Central manager for device discovery, status polling, and commands
@Observable
@MainActor
final class DeviceManager {
    /// All discovered devices keyed by name
    private(set) var devices: [String: Device] = [:]
    
    /// Sorted array of devices for display
    var sortedDevices: [Device] {
        devices.values.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
    
    /// Whether discovery is active
    private(set) var isScanning: Bool = false
    
    /// Last error message
    private(set) var lastError: String?
    
    private let discovery = NetworkDiscovery()
    private let apiClient = WiiMAPIClient()
    private var discoveryTask: Task<Void, Never>?
    private var pollingTasks: [String: Task<Void, Never>] = [:]
    
    /// Polling interval in seconds
    private let pollingInterval: TimeInterval = 4.0
    
    /// Enable mock devices for simulator testing
    var useMockDevices: Bool = false
    
    init() {
        // Start discovery on init
        Task {
            await startDiscovery()
        }
    }
    
    // MARK: - Discovery
    
    /// Start network discovery
    func startDiscovery() async {
        // Cancel existing discovery
        discoveryTask?.cancel()
        isScanning = true
        lastError = nil
        
        #if targetEnvironment(simulator)
        // Add mock devices for simulator testing
        if useMockDevices || devices.isEmpty {
            addMockDevices()
            isScanning = false
            return
        }
        #endif
        
        discoveryTask = Task {
            let events = await discovery.startDiscovery()
            
            for await event in events {
                guard !Task.isCancelled else { break }
                
                switch event {
                case .deviceFound(let name, let ipAddress, let port, let type):
                    await handleDeviceFound(name: name, ipAddress: ipAddress, port: port, type: type)
                    
                case .deviceLost(let name):
                    await handleDeviceLost(name: name)
                    
                case .error(let error):
                    lastError = error.localizedDescription
                }
            }
        }
        
        // Mark scanning complete after a brief period
        Task {
            try? await Task.sleep(for: .seconds(3))
            isScanning = false
        }
    }
    
    /// Stop discovery and all polling
    func stopDiscovery() async {
        discoveryTask?.cancel()
        await discovery.stopDiscovery()
        pollingTasks.values.forEach { $0.cancel() }
        pollingTasks.removeAll()
        isScanning = false
    }
    
    /// Refresh the network (restart discovery)
    func refreshNetwork() async {
        await stopDiscovery()
        devices.removeAll()
        await startDiscovery()
    }
    
    private func handleDeviceFound(name: String, ipAddress: String, port: Int, type: DeviceType) async {
        // Check if device already exists
        if let existing = devices[name] {
            // Update IP if changed
            if existing.ipAddress != ipAddress {
                let updated = Device(
                    id: existing.id,
                    name: name,
                    ipAddress: ipAddress,
                    port: port,
                    type: type,
                    status: existing.status,
                    isOnline: true
                )
                devices[name] = updated
                startPolling(for: updated)
            }
        } else {
            // Add new device
            let device = Device(name: name, ipAddress: ipAddress, port: port, type: type)
            devices[name] = device
            startPolling(for: device)
        }
    }
    
    private func handleDeviceLost(name: String) async {
        if let device = devices[name] {
            device.isOnline = false
            pollingTasks[name]?.cancel()
            pollingTasks.removeValue(forKey: name)
        }
    }
    
    // MARK: - Status Polling
    
    private func startPolling(for device: Device) {
        // Cancel existing polling for this device
        pollingTasks[device.name]?.cancel()
        
        pollingTasks[device.name] = Task {
            while !Task.isCancelled {
                await pollDeviceStatus(device)
                try? await Task.sleep(for: .seconds(pollingInterval))
            }
        }
    }
    
    private func pollDeviceStatus(_ device: Device) async {
        do {
            let status = try await apiClient.getStatus(from: device)
            device.status = status
            device.isOnline = true
            device.lastSeen = Date()
        } catch {
            // Mark offline after multiple failures could be added here
            print("[Polling] Error for \(device.name): \(error.localizedDescription)")
        }
    }
    
    // MARK: - Commands
    
    /// Set volume for a device
    func setVolume(_ level: Int, for device: Device) async {
        do {
            try await apiClient.setVolume(level, on: device)
            device.status.volume = level
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Toggle mute for a device
    func toggleMute(for device: Device) async {
        let newMuteState = !device.status.isMuted
        do {
            try await apiClient.setMute(newMuteState, on: device)
            device.status.isMuted = newMuteState
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Toggle play/pause for a device
    func togglePlayPause(for device: Device) async {
        do {
            try await apiClient.togglePlayPause(on: device)
            // Optimistically update state
            switch device.status.playbackState {
            case .playing:
                device.status.playbackState = .paused
            case .paused, .stopped, .idle:
                device.status.playbackState = .playing
            }
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    /// Trigger a preset on a device
    func triggerPreset(_ preset: Int, for device: Device) async {
        do {
            try await apiClient.triggerPreset(preset, on: device)
        } catch {
            lastError = error.localizedDescription
        }
    }
    
    // MARK: - Mock Devices (for simulator)
    
    private func addMockDevices() {
        let zones: [(name: String, model: String, type: DeviceType)] = [
            // Conference Room
            ("Conference Room: MOS", "WiiM Pro", .wiim),
            ("Conference Room: 602", "WiiM Amp", .wiim),
            ("Conference Room: 802 Sub", "WiiM Pro", .wiim),
            ("Conference Room: 803", "WiiM Amp", .wiim),
            // Lobby
            ("Lobby: PS80", "WiiM Pro", .wiim),
            ("Lobby: Pendants", "WiiM Amp", .wiim),
            // Showroom
            ("Showroom: Pendants", "WiiM Pro", .wiim),
            ("Showroom: P10Sub (x4)", "WiiM Amp", .wiim),
            ("Showroom: Pro Pendants", "WiiM Pro", .wiim),
            // Planter Wall
            ("Planter Wall: ASM63", "Node 2i", .bluesound),
            ("Planter Wall: ALSB106", "Powernode", .bluesound),
            ("Planter Wall: ALSB85", "Node 2i", .bluesound),
            ("Planter Wall: ALSB64", "Powernode", .bluesound),
            ("Planter Wall: LSH80", "Node 2i", .bluesound),
            ("Planter Wall: LSH60", "Powernode", .bluesound),
            ("Planter Wall: LSH40", "Node 2i", .bluesound),
            // Other
            ("Hallway: Planter", "WiiM Pro", .wiim),
            ("Front Yard: Bollards", "WiiM Amp", .wiim)
        ]
        
        for (index, zone) in zones.enumerated() {
            let status: DeviceStatus
            // Give some devices playing status for variety
            if index % 4 == 0 {
                status = DeviceStatus(
                    source: .spotify,
                    playbackState: .playing,
                    artist: "Demo Track",
                    title: "Origin Acoustics",
                    volume: 50 + (index % 30),
                    isMuted: false
                )
            } else if index % 4 == 1 {
                status = DeviceStatus(
                    source: .airplay,
                    playbackState: .paused,
                    artist: nil,
                    title: nil,
                    volume: 40 + (index % 20),
                    isMuted: false
                )
            } else {
                status = .idle
            }
            
            let device = Device(
                name: zone.name,
                model: zone.model,
                ipAddress: "192.168.1.\(100 + index)",
                type: zone.type,
                status: status
            )
            devices[zone.name] = device
        }
    }
}
