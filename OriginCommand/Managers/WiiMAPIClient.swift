import Foundation

/// Linkplay API client for WiiM devices
actor WiiMAPIClient {
    private let session: URLSession
    private let timeout: TimeInterval = 5.0
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 5.0
        config.timeoutIntervalForResource = 10.0
        self.session = URLSession(configuration: config)
    }
    
    /// Fetch current player status from device
    func getStatus(from device: Device) async throws -> DeviceStatus {
        guard let baseURL = device.baseURL else {
            throw APIError.invalidURL
        }
        
        let url = baseURL.appendingPathComponent("httpapi.asp")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "command", value: "getPlayerStatus")]
        
        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }
        
        let (data, response) = try await session.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw APIError.invalidResponse
        }
        
        return try parseStatusResponse(data)
    }
    
    /// Set volume level (0-100)
    func setVolume(_ level: Int, on device: Device) async throws {
        let clampedLevel = max(0, min(100, level))
        try await sendCommand("setPlayerCmd:vol:\(clampedLevel)", to: device)
    }
    
    /// Toggle mute state
    func setMute(_ muted: Bool, on device: Device) async throws {
        let muteValue = muted ? 1 : 0
        try await sendCommand("setPlayerCmd:mute:\(muteValue)", to: device)
    }
    
    /// Toggle play/pause
    func togglePlayPause(on device: Device) async throws {
        try await sendCommand("setPlayerCmd:onepause", to: device)
    }
    
    /// Trigger preset (1-based index)
    func triggerPreset(_ preset: Int, on device: Device) async throws {
        try await sendCommand("MCUKeyShortClick:\(preset)", to: device)
    }
    
    // MARK: - Private Helpers
    
    private func sendCommand(_ command: String, to device: Device) async throws {
        guard let baseURL = device.baseURL else {
            throw APIError.invalidURL
        }
        
        let url = baseURL.appendingPathComponent("httpapi.asp")
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)!
        components.queryItems = [URLQueryItem(name: "command", value: command)]
        
        guard let requestURL = components.url else {
            throw APIError.invalidURL
        }
        
        let (_, response) = try await session.data(from: requestURL)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw APIError.commandFailed
        }
    }
    
    private func parseStatusResponse(_ data: Data) throws -> DeviceStatus {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw APIError.parseError
        }
        
        // Parse mode/source
        let mode = json["mode"] as? String ?? ""
        let source = DeviceSource.fromLinkplayMode(mode)
        
        // Parse volume
        let volumeString = json["vol"] as? String ?? "50"
        let volume = Int(volumeString) ?? 50
        
        // Parse mute state
        let muteString = json["mute"] as? String ?? "0"
        let isMuted = muteString == "1"
        
        // Parse playback state
        let statusString = json["status"] as? String ?? "stop"
        let playbackState: PlaybackState
        switch statusString.lowercased() {
        case "play": playbackState = .playing
        case "pause": playbackState = .paused
        case "stop": playbackState = .stopped
        default: playbackState = .idle
        }
        
        // Parse metadata (may be hex-encoded in Linkplay)
        var artist: String? = nil
        var title: String? = nil
        
        if let artistHex = json["Artist"] as? String {
            artist = decodeHexString(artistHex)
        }
        if let titleHex = json["Title"] as? String {
            title = decodeHexString(titleHex)
        }
        
        return DeviceStatus(
            source: source,
            playbackState: playbackState,
            artist: artist,
            title: title,
            volume: volume,
            isMuted: isMuted
        )
    }
    
    /// Decode hex-encoded string (Linkplay encodes metadata as hex)
    private func decodeHexString(_ hex: String) -> String? {
        guard !hex.isEmpty else { return nil }
        
        // If it's not hex, return as-is
        guard hex.allSatisfy({ $0.isHexDigit }) else {
            return hex
        }
        
        var bytes = [UInt8]()
        var index = hex.startIndex
        
        while index < hex.endIndex {
            let nextIndex = hex.index(index, offsetBy: 2, limitedBy: hex.endIndex) ?? hex.endIndex
            if let byte = UInt8(hex[index..<nextIndex], radix: 16) {
                bytes.append(byte)
            }
            index = nextIndex
        }
        
        return String(bytes: bytes, encoding: .utf8)
    }
}

// MARK: - Errors

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case commandFailed
    case parseError
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid device URL"
        case .invalidResponse: return "Invalid response from device"
        case .commandFailed: return "Command failed"
        case .parseError: return "Failed to parse response"
        }
    }
}
