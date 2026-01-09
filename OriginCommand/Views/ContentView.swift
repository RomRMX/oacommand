import SwiftUI

/// Main dashboard - compact layout for all zones on one screen
struct ContentView: View {
    @Environment(DeviceManager.self) private var deviceManager
    @Environment(\.openURL) private var openURL
    
    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.06, green: 0.06, blue: 0.1),
                        Color(red: 0.03, green: 0.03, blue: 0.06)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle accent orbs
                Circle()
                    .fill(Color.green.opacity(0.06))
                    .frame(width: 250, height: 250)
                    .blur(radius: 60)
                    .offset(x: -80, y: -40)
                
                Circle()
                    .fill(Color.blue.opacity(0.06))
                    .frame(width: 300, height: 300)
                    .blur(radius: 80)
                    .offset(x: geometry.size.width - 150, y: geometry.size.height - 150)
                
                VStack(spacing: 0) {
                    // Compact Header
                    HStack {
                        Text("OA Audio Zone Command Center")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
                        // App Shortcuts
                        HStack(spacing: 12) {
                            appShortcutButton(name: "Apple Music", icon: "music.note", color: Color(red: 0.98, green: 0.17, blue: 0.22), url: "music://")
                            appShortcutButton(name: "Spotify", icon: "waveform", color: Color(red: 0.11, green: 0.84, blue: 0.38), url: "spotify://")
                            appShortcutButton(name: "Tidal", icon: "waveform.path", color: .white, url: "tidal://")
                        }
                        .padding(.trailing, 16)
                        
                        Button {
                            Task { await deviceManager.refreshNetwork() }
                        } label: {
                            Text("REFRESH")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundStyle(deviceManager.isScanning ? .gray : .white)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 6)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule().strokeBorder(.white.opacity(0.2), lineWidth: 0.5)
                                }
                        }
                        .disabled(deviceManager.isScanning)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .padding(.top, 4)
                    
                    // Device Grid with ScrollView
                    ScrollView(showsIndicators: true) {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(deviceManager.sortedDevices) { device in
                                DeviceCardView(device: device)
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // Helper for app shortcut buttons
    private func appShortcutButton(name: String, icon: String, color: Color, url: String) -> some View {
        Button {
            if let url = URL(string: url) {
                openURL(url)
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 12))
                Text(name)
                    .font(.system(size: 10, weight: .semibold))
            }
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(color.opacity(0.1))
            .clipShape(Capsule())
            .overlay(Capsule().strokeBorder(color.opacity(0.3), lineWidth: 0.5))
        }
    }
}

#Preview {
    ContentView()
        .environment(DeviceManager())
}
