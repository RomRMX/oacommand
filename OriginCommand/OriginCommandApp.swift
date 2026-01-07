import SwiftUI

@main
struct OriginCommandApp: App {
    @State private var deviceManager = DeviceManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(deviceManager)
        }
    }
}
