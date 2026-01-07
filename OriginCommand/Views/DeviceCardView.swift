import SwiftUI

/// Ultra-compact glassmorphism device card - fits 18 on one screen
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
        VStack(spacing: 3) {
            // Row 1: Device Name + Track Info + Status
            HStack(spacing: 4) {
                // Status dot
                Circle()
                    .fill(device.isOnline ? accentColor : Color.red)
                    .frame(width: 4, height: 4)
                
                // Device name
                Text(device.name)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                
                Spacer()
                
                // Track info (compact)
                if let title = device.status.title, !title.isEmpty {
                    Text(title)
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.5))
                        .lineLimit(1)
                        .frame(maxWidth: 80)
                }
                
                // Playing indicator
                if device.status.playbackState == .playing {
                    Image(systemName: "waveform")
                        .font(.system(size: 8))
                        .foregroundStyle(accentColor)
                }
            }
            
            // Row 2: Transport + Volume (all in one row)
            HStack(spacing: 4) {
                // Rewind
                Button {
                } label: {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                // Play/Pause
                Button {
                    Task { await deviceManager.togglePlayPause(for: device) }
                } label: {
                    Image(systemName: device.status.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.white)
                        .frame(width: 24, height: 24)
                        .background(accentColor.opacity(0.25))
                        .clipShape(Circle())
                        .overlay { Circle().strokeBorder(accentColor.opacity(0.5), lineWidth: 0.5) }
                }
                
                // Forward
                Button {
                } label: {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 8))
                        .foregroundStyle(.white.opacity(0.7))
                        .frame(width: 20, height: 20)
                        .background(Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                // Mute
                Button {
                    Task { await deviceManager.toggleMute(for: device) }
                } label: {
                    Image(systemName: device.status.isMuted ? "speaker.slash.fill" : "speaker.fill")
                        .font(.system(size: 7))
                        .foregroundStyle(device.status.isMuted ? .red : .white.opacity(0.6))
                        .frame(width: 18, height: 18)
                        .background(device.status.isMuted ? Color.red.opacity(0.15) : Color.white.opacity(0.08))
                        .clipShape(Circle())
                }
                
                // Volume Slider - fills remaining space
                Slider(value: $localVolume, in: 0...100, step: 1) { editing in
                    isDraggingVolume = editing
                    if !editing { Task { await deviceManager.setVolume(Int(localVolume), for: device) } }
                }
                .tint(accentColor)
                
                Text("\(Int(isDraggingVolume ? localVolume : Double(device.status.volume)))%")
                    .font(.system(size: 8, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 22)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.ultraThinMaterial)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(LinearGradient(
                            colors: [accentColor.opacity(0.1), accentColor.opacity(0.03)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.2), .white.opacity(0.05), accentColor.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 0.5
                )
        }
        .onAppear { localVolume = Double(device.status.volume) }
        .onChange(of: device.status.volume) { _, newValue in
            if !isDraggingVolume { localVolume = Double(newValue) }
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            ForEach(0..<4) { i in
                DeviceCardView(device: Device(
                    name: "Zone \(i): Speaker",
                    ipAddress: "192.168.1.\(100 + i)",
                    type: i % 2 == 0 ? .wiim : .bluesound,
                    status: .idle
                ))
            }
        }
        .padding()
    }
    .environment(DeviceManager())
}
