import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var electricityService: ElectricityService
    @Environment(\.colorScheme) private var colorScheme
    
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
                                Text("Mostrando datos estimados")
                                    .font(.subheadline)
                                    .padding(.top, 4)
                                    .foregroundColor(.secondary)
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
            .navigationTitle("Precios Luz Sanlúcar")
            .toolbar {
                Button(action: {
                    electricityService.fetchPriceData()
                }) {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .refreshable {
                electricityService.fetchPriceData()
            }
        }
        .preferredColorScheme(colorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(ElectricityService())
} 