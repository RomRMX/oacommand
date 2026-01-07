import SwiftUI

/// Efficient 2-column wide card with streaming shortcuts
struct DeviceCardView: View {
    @Environment(DeviceManager.self) private var deviceManager
    @Environment(\.openURL) private var openURL
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
        VStack(spacing: 8) {
            // Row 1: Header - Device Name & Model
            HStack(alignment: .center) {
                // Status & Name
                HStack(spacing: 6) {
                    Circle()
                        .fill(device.isOnline ? accentColor : Color.red)
                        .frame(width: 6, height: 6)
                        .shadow(color: device.isOnline ? accentColor.opacity(0.5) : .clear, radius: 2)
                    
                    Text(device.name)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                }
                
                Spacer()
                
                // Model Badge (Static)
                Text(device.model)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.6))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.1))
                    .clipShape(Capsule())
            }
            
            // Row 2: Controls, Info, Shortcuts
            HStack(alignment: .center, spacing: 12) {
                // Playback Controls
                HStack(spacing: 2) {
                    Button { } label: { controlButton(icon: "backward.fill", size: 10) }
                    
                    Button {
                        Task { await deviceManager.togglePlayPause(for: device) }
                    } label: {
                        Image(systemName: device.status.playbackState == .playing ? "pause.circle.fill" : "play.circle.fill")
                            .font(.system(size: 28))
                            .foregroundStyle(.white)
                            .shadow(radius: 2)
                    }
                    
                    Button { } label: { controlButton(icon: "forward.fill", size: 10) }
                }
                
                // Track Info (Middle)
                VStack(alignment: .leading, spacing: 1) {
                    Text(device.status.title ?? "No Track")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                    
                    Text(device.status.artist ?? "Unknown Artist")
                        .font(.system(size: 10))
                        .foregroundStyle(.white.opacity(0.6))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                
                // IP Address (Right)
                Button {
                    editedIP = device.ipAddress
                    showingIPEditor = true
                } label: {
                    HStack(spacing: 3) {
                        Image(systemName: "network")
                            .font(.system(size: 8))
                            .foregroundStyle(.white.opacity(0.3))
                        Text(device.ipAddress)
                            .font(.system(size: 9, weight: .medium, design: .monospaced))
                            .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            
            // Row 3: Volume
            HStack(spacing: 8) {
                Button {
                    Task { await deviceManager.toggleMute(for: device) }
                } label: {
                    Image(systemName: device.status.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(device.status.isMuted ? .red : .white.opacity(0.6))
                        .frame(width: 20, alignment: .center)
                }
                
                Slider(value: $localVolume, in: 0...100, step: 1) { editing in
                    isDraggingVolume = editing
                    if !editing { Task { await deviceManager.setVolume(Int(localVolume), for: device) } }
                }
                .tint(accentColor)
                .frame(height: 12)
                
                Text("\(Int(isDraggingVolume ? localVolume : Double(device.status.volume)))%")
                    .font(.system(size: 10, weight: .medium).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 28, alignment: .trailing)
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
                        colors: [.white.opacity(0.1), .white.opacity(0.02), accentColor.opacity(0.1)],
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
    
    // Components
    
    private func controlButton(icon: String, size: CGFloat) -> some View {
        Image(systemName: icon)
            .font(.system(size: size))
            .foregroundStyle(.white.opacity(0.7))
            .frame(width: 24, height: 24)
            .background(Color.white.opacity(0.05))
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
            // Header with simple close
            HStack {
                Text(deviceName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            Text(model).font(.caption).foregroundStyle(.white.opacity(0.5))
            
            Divider().background(.white.opacity(0.2))
            
            TextField("IP Address", text: $editedIP)
                .font(.system(.body, design: .monospaced))
                .padding(8)
                .background(Color.white.opacity(0.1))
                .cornerRadius(6)
            
            Button("Save Update", action: onSave)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.black)
                .frame(maxWidth: .infinity)
                .padding(10)
                .background(Color.green)
                .cornerRadius(8)
        }
        .padding()
        .frame(width: 240)
        .background(Color(white: 0.15))
        .preferredColorScheme(.dark)
    }
}
