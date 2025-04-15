import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var electricityService: ElectricityService
    @Environment(\.colorScheme) private var colorScheme
    @State private var showingCityPicker = false
    @State private var showingAboutView = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    if electricityService.isLoading {
                        ProgressView("Cargando precios...")
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else if let errorMessage = electricityService.errorMessage {
                        VStack {
                            Image(systemName: "exclamationmark.triangle")
                                .font(.system(size: 50))
                                .foregroundColor(.orange)
                                .padding()
                            
                            Text("Aviso")
                                .font(.title2)
                                .fontWeight(.bold)
                                .padding(.bottom, 4)
                            
                            Text(errorMessage)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                                .foregroundColor(.secondary)
                                
                            if !electricityService.dailyData.prices.isEmpty {
                                if electricityService.isUsingMockData {
                                    Text("⚠️ ATENCIÓN: Se muestran datos aproximados ⚠️")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                        .padding(.top, 8)
                                        .multilineTextAlignment(.center)
                                        
                                    Text("Los precios NO son reales")
                                        .font(.subheadline)
                                        .foregroundColor(.orange)
                                        .padding(.bottom, 8)
                                } else {
                                    Text("Mostrando datos estimados")
                                        .font(.subheadline)
                                        .padding(.top, 4)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Button("Reintentar") {
                                electricityService.fetchPriceData()
                            }
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                            .padding(.top)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(radius: 2)
                        .padding()
                        
                        if !electricityService.dailyData.prices.isEmpty {
                            Text("Datos \(electricityService.dataSource.lowercased())")
                                .font(.headline)
                                .padding(.top)
                                
                            PriceDetailView(
                                currentPrice: electricityService.dailyData.currentPrice,
                                lowestPrice: electricityService.dailyData.lowestPrice,
                                highestPrice: electricityService.dailyData.highestPrice,
                                averagePrice: electricityService.dailyData.averagePrice
                            )
                            .padding(.horizontal)
                            
                            PriceChartView(
                                prices: electricityService.dailyData.prices,
                                lowestPrice: electricityService.dailyData.lowestPrice,
                                highestPrice: electricityService.dailyData.highestPrice
                            )
                            .padding(.horizontal)
                        }
                    } else if electricityService.dailyData.prices.isEmpty {
                        Text("No hay datos disponibles")
                            .font(.headline)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .padding(.top, 100)
                    } else {
                        PriceDetailView(
                            currentPrice: electricityService.dailyData.currentPrice,
                            lowestPrice: electricityService.dailyData.lowestPrice,
                            highestPrice: electricityService.dailyData.highestPrice,
                            averagePrice: electricityService.dailyData.averagePrice
                        )
                        .padding(.horizontal)
                        
                        Text("Fuente: Datos \(electricityService.dataSource.lowercased())")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                            .padding(.horizontal)
                        
                        PriceChartView(
                            prices: electricityService.dailyData.prices,
                            lowestPrice: electricityService.dailyData.lowestPrice,
                            highestPrice: electricityService.dailyData.highestPrice
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Precios Luz \(electricityService.selectedCity?.name ?? "España")")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        electricityService.fetchPriceData()
                    }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showingCityPicker = true
                    }) {
                        HStack {
                            Image(systemName: "location.circle")
                            Text("Cambiar")
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAboutView = true
                    }) {
                        Image(systemName: "info.circle")
                    }
                }
            }
            .refreshable {
                electricityService.fetchPriceData()
            }
            .overlay(
                Group {
                    if electricityService.isUsingMockData && electricityService.errorMessage == nil {
                        VStack {
                            Text("⚠️ DATOS ESTIMADOS ⚠️")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("Los precios mostrados son aproximados, no reales")
                                .font(.caption)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.orange)
                        .cornerRadius(8)
                        .shadow(radius: 2)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .transition(.move(edge: .top))
                        .animation(.spring(), value: electricityService.isUsingMockData)
                        .offset(y: 60)
                    }
                }
            )
            .sheet(isPresented: $showingCityPicker) {
                CityPickerView()
                    .environmentObject(electricityService)
            }
            .sheet(isPresented: $showingAboutView) {
                InformationView()
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

// Local wrapper for CitySelectionView to avoid import issues
struct CityPickerView: View {
    @EnvironmentObject private var electricityService: ElectricityService
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    
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
        NavigationView {
            VStack {
                TextField("Buscar ciudad...", text: $searchText)
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding(.horizontal)
                
                List {
                    ForEach(filteredCities) { city in
                        Button(action: {
                            electricityService.saveSelectedCity(city)
                            dismiss()
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
            .navigationTitle("Selecciona tu ciudad")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// Local wrapper for AboutView to avoid import issues
struct InformationView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("ElecPrice es una aplicación iOS que muestra los precios de electricidad en tiempo real para España.")
                        .font(.body)
                        .padding(.bottom)
                    
                    Group {
                        Text("Características")
                            .font(.headline)
                        
                        Text("• Muestra los precios de electricidad por hora\n• Indica el precio actual, más bajo y más alto del día\n• Visualiza los precios en un gráfico de líneas\n• Utiliza datos en tiempo real cuando es posible\n• Funciona con datos aproximados cuando no hay conexión")
                    }
                    
                    Group {
                        Text("Fuentes de datos")
                            .font(.headline)
                            .padding(.top)
                        
                        Text("La aplicación obtiene datos de tarifaluzhora.es y la API de Red Eléctrica de España.")
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .navigationTitle("Acerca de")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ElectricityService())
} 