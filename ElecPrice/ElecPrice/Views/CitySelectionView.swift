import SwiftUI

struct CitySelectionView: View {
    @EnvironmentObject private var electricityService: ElectricityService
    @State private var searchText = ""
    @Environment(\.colorScheme) private var colorScheme
    
    var filteredCities: [City] {
        if searchText.isEmpty {
            return electricityService.availableCities
        } else {
            return electricityService.availableCities.filter { city in
                city.name.lowercased().contains(searchText.lowercased())
            }
        }
    }
    
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
            
            SearchBar(text: $searchText)
                .padding(.horizontal)
            
            List {
                ForEach(filteredCities) { city in
                    Button(action: {
                        electricityService.saveSelectedCity(city)
                    }) {
                        HStack {
                            Text(city.name)
                                .foregroundColor(colorScheme == .dark ? .white : .black)
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

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            
            TextField("Buscar ciudad...", text: $text)
                .disableAutocorrection(true)
            
            if !text.isEmpty {
                Button(action: {
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

#Preview {
    CitySelectionView()
        .environmentObject(ElectricityService())
} 