import SwiftUI

/// Glassmorphism device control card with full transport controls
struct DeviceCardView: View {
    @Environment(DeviceManager.self) private var deviceManager
    let device: Device
    
    @State private var localVolume: Double = 50
    @State private var isDraggingVolume: Bool = false
    
    private var accentColor: Color {
        switch device.type {
        case .wiim:
            return Color(red: 0.2, green: 0.9, blue: 0.5)
        case .bluesound:
            return Color(red: 0.3, green: 0.6, blue: 1.0)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Row 1: Device Name + Status Indicator
            HStack(alignment: .center) {
                Text(device.name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(device.isOnline ? accentColor : Color.red)
                        .frame(width: 5, height: 5)
                    
                    if device.status.playbackState == .playing {
                        Image(systemName: "waveform")
                            .font(.system(size: 9))
                            .foregroundStyle(accentColor)
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.top, 8)
            .padding(.bottom, 4)
            
            // Row 2: Artist & Track Name (2 lines)
            VStack(alignment: .leading, spacing: 1) {
                Text(device.status.title ?? "No Track")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                
                Text(device.status.artist ?? "Unknown Artist")
                    .font(.system(size: 9))
                    .foregroundStyle(.white.opacity(0.5))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 10)
            .padding(.bottom, 6)
            
            // Row 3: Transport Controls
            HStack(spacing: 6) {
                // Rewind
                Button {
                    // Rewind action - seek backward
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Play/Pause
                Button {
                    Task {
                        await deviceManager.togglePlayPause(for: device)
                    }
                } label: {
                    Image(systemName: device.status.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(accentColor.opacity(0.3))
                        .clipShape(Circle())
                        .overlay {
                            Circle()
                                .strokeBorder(accentColor.opacity(0.6), lineWidth: 1)
                        }
                }
                
                // Forward
                Button {
                    // Forward action - skip next
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.8))
                        .frame(width: 26, height: 26)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Mute
                Button {
                    Task {
                        await deviceManager.toggleMute(for: device)
                    }
                } label: {
                    Image(systemName: device.status.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 9))
                        .foregroundStyle(device.status.isMuted ? .red : .white.opacity(0.7))
                        .frame(width: 26, height: 26)
                        .background(device.status.isMuted ? Color.red.opacity(0.2) : Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                Spacer()
                
                // Volume Slider
                HStack(spacing: 4) {
                    Slider(
                        value: $localVolume,
                        in: 0...100,
                        step: 1
                    ) { editing in
                        isDraggingVolume = editing
                        if !editing {
                            Task {
                                await deviceManager.setVolume(Int(localVolume), for: device)
                            }
                        }
                    }
                    .tint(accentColor)
                    
                    Text("\(Int(isDraggingVolume ? localVolume : Double(device.status.volume)))%")
                        .font(.system(size: 9, weight: .medium).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.6))
                        .frame(width: 26, alignment: .trailing)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
        .background {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(.ultraThinMaterial)
                .background {
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.12), accentColor.opacity(0.04)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.25), .white.opacity(0.08), accentColor.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        }
        .shadow(color: accentColor.opacity(0.15), radius: 6, x: 0, y: 3)
        .onAppear {
            localVolume = Double(device.status.volume)
        }
        .onChange(of: device.status.volume) { _, newValue in
            if !isDraggingVolume {
                localVolume = Double(newValue)
            }
        }
    }
}

#Preview {
    let manager = DeviceManager()
    
    return ZStack {
        LinearGradient(
            colors: [Color(red: 0.08, green: 0.08, blue: 0.12), Color.black],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            DeviceCardView(device: Device(
                name: "Lobby: PS80",
                ipAddress: "192.168.1.100",
                type: .wiim,
                status: DeviceStatus(
                    source: .spotify,
                    playbackState: .playing,
                    artist: "Eagles",
                    title: "Hotel California",
                    volume: 65,
                    isMuted: false
                )
            ))
            DeviceCardView(device: Device(
                name: "Conference Room: MOS",
                ipAddress: "192.168.1.101",
                type: .bluesound,
                status: .idle
            ))
        }
        .padding()
    }
    .environment(manager)
}
