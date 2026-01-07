import SwiftUI

/// Ultra-compact glassmorphism device card with model display and IP editor
struct DeviceCardView: View {
    @Environment(DeviceManager.self) private var deviceManager
    let device: Device
    
    @State private var localVolume: Double = 50
    @State private var isDraggingVolume: Bool = false
    @State private var showingIPEditor: Bool = false
    @State private var editedIP: String = ""
    
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
            // Row 1: Device Name + Model (clickable) + Status
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
                
                // Device Model - Clickable for IP settings
                Button {
                    editedIP = device.ipAddress
                    showingIPEditor = true
                } label: {
                    HStack(spacing: 3) {
                        Text(device.model)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Image(systemName: "info.circle")
                            .font(.system(size: 7))
                            .foregroundStyle(.white.opacity(0.3))
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 2)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                }
                .popover(isPresented: $showingIPEditor) {
                    IPEditorView(
                        deviceName: device.name,
                        model: device.model,
                        currentIP: device.ipAddress,
                        editedIP: $editedIP,
                        onSave: {
                            deviceManager.updateIPAddress(editedIP, for: device)
                            showingIPEditor = false
                        },
                        onDismiss: {
                            showingIPEditor = false
                        }
                    )
                }
                
                // Playing indicator
                if device.status.playbackState == .playing {
                    Image(systemName: "waveform")
                        .font(.system(size: 8))
                        .foregroundStyle(accentColor)
                }
            }
            
            // Row 2: Transport + Volume
            HStack(spacing: 4) {
                // Rewind
                Button { } label: {
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
                Button { } label: {
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
                
                // Volume Slider
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

/// IP Address editor popover
struct IPEditorView: View {
    let deviceName: String
    let model: String
    let currentIP: String
    @Binding var editedIP: String
    let onSave: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(deviceName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(.white)
                    Text(model)
                        .font(.system(size: 11))
                        .foregroundStyle(.white.opacity(0.6))
                }
                Spacer()
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white.opacity(0.4))
                }
            }
            
            Divider().background(.white.opacity(0.2))
            
            // IP Address field
            VStack(alignment: .leading, spacing: 4) {
                Text("IP Address")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                
                TextField("xxx.xxx.xxx.xxx", text: $editedIP)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .keyboardType(.decimalPad)
            }
            
            // Save button
            Button {
                onSave()
            } label: {
                Text("Save")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.black)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color.green)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding(16)
        .frame(width: 260)
        .background(Color(red: 0.1, green: 0.1, blue: 0.14))
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
            DeviceCardView(device: Device(
                name: "Lobby: PS80",
                model: "WiiM Pro",
                ipAddress: "192.168.1.100",
                type: .wiim,
                status: DeviceStatus(source: .spotify, playbackState: .playing, artist: "Eagles", title: "Hotel California", volume: 65, isMuted: false)
            ))
            DeviceCardView(device: Device(
                name: "Planter Wall: ASM63",
                model: "Node 2i",
                ipAddress: "192.168.1.101",
                type: .bluesound,
                status: .idle
            ))
        }
        .padding()
    }
    .environment(DeviceManager())
}
