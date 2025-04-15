import SwiftUI

@main
struct ElecPriceApp: App {
    @StateObject private var electricityService = ElectricityService()
    @State private var showingContentView = false
    
    var body: some Scene {
        WindowGroup {
            Group {
                if electricityService.isCitySelected || showingContentView {
                    ContentView()
                        .environmentObject(electricityService)
                } else {
                    MainCitySelectionView(showContentView: $showingContentView)
                        .environmentObject(electricityService)
                }
            }
        }
    }
}

// Wrapper view to avoid import issues
struct MainCitySelectionView: View {
    @EnvironmentObject private var electricityService: ElectricityService
    @Binding var showContentView: Bool
    
    var body: some View {
        VStack {
            Text("Selecciona tu ciudad")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            
            Text("ElecPrice mostrará precios de electricidad para la ciudad que elijas.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .padding(.bottom)
            
            List {
                ForEach(electricityService.availableCities) { city in
                    Button(action: {
                        electricityService.saveSelectedCity(city)
                        showContentView = true
                    }) {
                        HStack {
                            Text(city.name)
                            Spacer()
                            Image(systemName: "location.circle")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
        }
        .background(Color(.systemGroupedBackground))
    }
} 