import SwiftUI

/// Device card with detailed layout - fits 20 on screen (4 cols x 5 rows)
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
        VStack(alignment: .leading, spacing: 6) {
            // 1. Header: Airplay Name (Title)
            HStack(alignment: .top) {
                Text(device.name)
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
                
                Spacer()
                
                // Status Indicator
                Circle()
                    .fill(device.isOnline ? accentColor : Color.red)
                    .frame(width: 6, height: 6)
                    .shadow(color: device.isOnline ? accentColor.opacity(0.5) : .clear, radius: 2)
                    .padding(.top, 4)
            }
            
            // 2. Metadata: Song & Artist
            VStack(alignment: .leading, spacing: 2) {
                Text(device.status.title ?? "No Track")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.white.opacity(0.9))
                    .lineLimit(1)
                
                Text(device.status.artist ?? "Unknown Artist")
                    .font(.system(size: 10))
                    .foregroundStyle(.white.opacity(0.6))
                    .lineLimit(1)
            }
            
            Spacer(minLength: 4)
            
            // 3. Controls Row
            HStack(spacing: 0) {
                // Rewind
                Button { } label: { controlButton(icon: "backward.fill", size: 12) }
                    .frame(maxWidth: .infinity)
                
                // Play/Pause
                Button {
                    Task { await deviceManager.togglePlayPause(for: device) }
                } label: {
                    Image(systemName: device.status.playbackState == .playing ? "pause.fill" : "play.fill")
                        .font(.system(size: 16)) // Slightly larger
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(accentColor.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(Circle().strokeBorder(accentColor.opacity(0.4), lineWidth: 1))
                }
                .frame(maxWidth: .infinity)
                
                // Forward
                Button { } label: { controlButton(icon: "forward.fill", size: 12) }
                    .frame(maxWidth: .infinity)
                
                // Mute
                Button {
                    Task { await deviceManager.toggleMute(for: device) }
                } label: {
                    Image(systemName: device.status.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(device.status.isMuted ? .red : .white.opacity(0.7))
                        .frame(width: 28, height: 28)
                        .background(device.status.isMuted ? Color.red.opacity(0.15) : Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity)
            }
            
            // 4. Volume Row
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.system(size: 8))
                    .foregroundStyle(.white.opacity(0.3))
                
                Slider(value: $localVolume, in: 0...100, step: 1) { editing in
                    isDraggingVolume = editing
                    if !editing { Task { await deviceManager.setVolume(Int(localVolume), for: device) } }
                }
                .tint(accentColor)
                .frame(height: 20)
                
                Text("\(Int(isDraggingVolume ? localVolume : Double(device.status.volume)))%")
                    .font(.system(size: 9, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.6))
                    .frame(width: 24, alignment: .trailing)
            }
            
            // 5. Footer: Model Name
            Button {
                editedIP = device.ipAddress
                showingIPEditor = true
            } label: {
                Text(device.model)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.horizontal, 6)
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
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .background {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(LinearGradient(
                            colors: [accentColor.opacity(0.08), accentColor.opacity(0.02)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                }
        }
        .overlay {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [.white.opacity(0.15), .white.opacity(0.05), accentColor.opacity(0.1)],
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
    
    // Helper helper for standard transport controls
    private func controlButton(icon: String, size: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: size))
            .foregroundStyle(.white.opacity(0.8))
            .frame(width: 28, height: 28)
            .background(Color.white.opacity(0.08))
            .clipShape(Circle())
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
        ScrollView {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 4), spacing: 8) {
                ForEach(0..<20) { i in
                    DeviceCardView(device: Device(
                        name: "Conference Room \(i)",
                        model: "WiiM Pro",
                        ipAddress: "192.168.1.\(100+i)",
                        type: i % 2 == 0 ? .wiim : .bluesound,
                         status: DeviceStatus(source: .spotify, playbackState: .playing, artist: "The Eagles", title: "Hotel California - 2013 Remaster", volume: 65, isMuted: false)
                    ))
                }
            }
            .padding()
        }
    }
    .environment(DeviceManager())
}
