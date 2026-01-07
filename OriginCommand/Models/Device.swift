import Foundation

/// Represents the type of audio streaming device
enum DeviceType: String, Codable, Sendable {
    case wiim = "WiiM"
    case bluesound = "Bluesound"
    
    /// Accent color name for this device type
    var accentColorName: String {
        switch self {
        case .wiim: return "WiiMGreen"
        case .bluesound: return "BluesoundBlue"
        }
    }
}

/// Represents the current playback state of a device
enum PlaybackState: String, Codable, Sendable {
    case playing = "Playing"
    case paused = "Paused"
    case stopped = "Stopped"
    case idle = "Idle"
}

/// Represents a source/input on the device
struct DeviceSource: Equatable, Sendable {
    let name: String
    let iconName: String
    
    static let unknown = DeviceSource(name: "Unknown", iconName: "speaker.wave.2")
    static let spotify = DeviceSource(name: "Spotify Connect", iconName: "music.note")
    static let airplay = DeviceSource(name: "AirPlay", iconName: "airplayaudio")
    static let tidal = DeviceSource(name: "Tidal", iconName: "waveform")
    static let bluetooth = DeviceSource(name: "Bluetooth", iconName: "antenna.radiowaves.left.and.right")
    static let lineIn = DeviceSource(name: "Line In", iconName: "cable.connector")
    static let optical = DeviceSource(name: "Optical", iconName: "opticaldisc")
    static let idle = DeviceSource(name: "Ready", iconName: "speaker.wave.2")
    
    /// Map Linkplay mode values to source
    static func fromLinkplayMode(_ mode: String) -> DeviceSource {
        switch mode.lowercased() {
        case "spotify": return .spotify
        case "airplay": return .airplay
        case "tidal": return .tidal
        case "bluetooth": return .bluetooth
        case "line-in", "linein": return .lineIn
        case "optical": return .optical
        case "idle", "": return .idle
        default: return DeviceSource(name: mode.capitalized, iconName: "music.note")
        }
    }
}

/// Current status/state of a device
struct DeviceStatus: Equatable, Sendable {
    var source: DeviceSource
    var playbackState: PlaybackState
    var artist: String?
    var title: String?
    var volume: Int // 0-100
    var isMuted: Bool
    
    /// Formatted metadata string for display
    var metadataDisplay: String {
        if let artist = artist, let title = title, !artist.isEmpty, !title.isEmpty {
            return "\(title) - \(artist)"
        } else if let title = title, !title.isEmpty {
            return title
        } else if playbackState == .idle || playbackState == .stopped {
            return "Ready"
        }
        return ""
    }
    
    static let idle = DeviceStatus(
        source: .idle,
        playbackState: .idle,
        artist: nil,
        title: nil,
        volume: 50,
        isMuted: false
    )
}

/// Represents a discovered audio streaming device
@Observable
final class Device: Identifiable, Sendable {
    let id: UUID
    let name: String
    let ipAddress: String
    let port: Int
    let type: DeviceType
    
    var status: DeviceStatus
    var isOnline: Bool
    var lastSeen: Date
    
    init(
        id: UUID = UUID(),
        name: String,
        ipAddress: String,
        port: Int = 80,
        type: DeviceType,
        status: DeviceStatus = .idle,
        isOnline: Bool = true
    ) {
        self.id = id
        self.name = name
        self.ipAddress = ipAddress
        self.port = port
        self.type = type
        self.status = status
        self.isOnline = isOnline
        self.lastSeen = Date()
    }
    
    /// Base URL for API requests
    var baseURL: URL? {
        URL(string: "http://\(ipAddress):\(port)")
    }
}

// MARK: - Hashable conformance for SwiftUI
extension Device: Hashable {
    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
