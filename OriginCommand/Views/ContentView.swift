import SwiftUI

/// Main dashboard - compact layout for all zones on one screen
struct ContentView: View {
    @Environment(DeviceManager.self) private var deviceManager
    
    private let columns = [
        GridItem(.flexible(), spacing: 6),
        GridItem(.flexible(), spacing: 6)
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
                        Text("OA Command")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundStyle(.white)
                        
                        Spacer()
                        
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
                    
                    // Device Grid - No scroll, fits on screen
                    LazyVGrid(columns: columns, spacing: 6) {
                        ForEach(deviceManager.sortedDevices) { device in
                            DeviceCardView(device: device)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 12)
                    
                    Spacer(minLength: 0)
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    ContentView()
        .environment(DeviceManager())
}
