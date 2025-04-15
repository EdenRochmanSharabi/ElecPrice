import SwiftUI

@main
struct ElecPriceApp: App {
    @StateObject private var electricityService = ElectricityService()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(electricityService)
        }
    }
} 