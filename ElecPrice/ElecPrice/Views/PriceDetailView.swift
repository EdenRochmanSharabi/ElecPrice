import SwiftUI

struct PriceDetailView: View {
    let currentPrice: Double
    let lowestPrice: ElectricityPrice?
    let highestPrice: ElectricityPrice?
    let averagePrice: Double
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        return formatter
    }()
    
    private func formatHour(_ date: Date?) -> String {
        guard let date = date else { return "N/A" }
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        return formatter.string(from: date)
    }
    
    private func formattedPrice(_ price: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: price)) ?? "N/A"
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Precio Actual")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                Text(formattedPrice(currentPrice))
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("por kWh")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
            
            HStack(spacing: 15) {
                PriceInfoCard(
                    title: "Precio Más Bajo",
                    price: lowestPrice?.price ?? 0,
                    time: formatHour(lowestPrice?.hour),
                    iconName: "arrow.down.circle.fill",
                    color: .green
                )
                
                PriceInfoCard(
                    title: "Precio Más Alto",
                    price: highestPrice?.price ?? 0,
                    time: formatHour(highestPrice?.hour),
                    iconName: "arrow.up.circle.fill",
                    color: .red
                )
            }
            
            VStack(alignment: .leading, spacing: 10) {
                Text("Precio Promedio Hoy")
                    .font(.headline)
                
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.blue)
                        .font(.system(size: 24))
                    
                    Text(formattedPrice(averagePrice))
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("por kWh")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
}

struct PriceInfoCard: View {
    let title: String
    let price: Double
    let time: String
    let iconName: String
    let color: Color
    
    private let currencyFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "€"
        formatter.minimumFractionDigits = 3
        formatter.maximumFractionDigits = 3
        return formatter
    }()
    
    private var formattedPrice: String {
        currencyFormatter.string(from: NSNumber(value: price)) ?? "N/A"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(alignment: .center) {
                Image(systemName: iconName)
                    .foregroundColor(color)
                    .font(.system(size: 28))
                
                VStack(alignment: .leading) {
                    Text(formattedPrice)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    Text("a las \(time)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    let lowestPrice = ElectricityPrice(hour: Date().addingTimeInterval(-3600 * 3), price: 0.08)
    let highestPrice = ElectricityPrice(hour: Date().addingTimeInterval(3600 * 3), price: 0.35)
    
    return PriceDetailView(
        currentPrice: 0.15,
        lowestPrice: lowestPrice,
        highestPrice: highestPrice,
        averagePrice: 0.21
    )
    .padding()
    .background(Color(.systemGroupedBackground))
} 