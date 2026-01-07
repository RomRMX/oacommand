import SwiftUI

/// Main dashboard view for OA Command with glassmorphism
struct ContentView: View {
    @Environment(DeviceManager.self) private var deviceManager
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient background for glassmorphism
                LinearGradient(
                    colors: [
                        Color(red: 0.08, green: 0.08, blue: 0.12),
                        Color(red: 0.05, green: 0.05, blue: 0.08)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                // Subtle accent orbs for depth
                GeometryReader { geo in
                    Circle()
                        .fill(Color.green.opacity(0.08))
                        .frame(width: 300, height: 300)
                        .blur(radius: 80)
                        .offset(x: -100, y: -50)
                    
                    Circle()
                        .fill(Color.blue.opacity(0.08))
                        .frame(width: 400, height: 400)
                        .blur(radius: 100)
                        .offset(x: geo.size.width - 200, y: geo.size.height - 200)
                }
                
                VStack(spacing: 0) {
                    // Header
                    headerView
                    
                    // Device Grid
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(deviceManager.sortedDevices) { device in
                                DeviceCardView(device: device)
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 16)
                    }
                }
            }
        }
        .preferredColorScheme(.dark)
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            Text("OA Command")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.white, .white.opacity(0.8)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Spacer()
            
            // Refresh Button - Glassmorphism pill
            Button {
                Task {
                    await deviceManager.refreshNetwork()
                }
            } label: {
                Text("REFRESH")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(deviceManager.isScanning ? .gray : .white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background {
                        Capsule()
                            .fill(.ultraThinMaterial)
                    }
                    .overlay {
                        Capsule()
                            .strokeBorder(
                                LinearGradient(
                                    colors: [.white.opacity(0.4), .white.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    }
            }
            .disabled(deviceManager.isScanning)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
    }
}

#Preview {
    ContentView()
        .environment(DeviceManager())
}
