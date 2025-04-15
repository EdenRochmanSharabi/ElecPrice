import SwiftUI
import Charts

struct PriceChartView: View {
    let prices: [ElectricityPrice]
    let lowestPrice: ElectricityPrice?
    let highestPrice: ElectricityPrice?
    
    private var priceRange: ClosedRange<Double> {
        let minPrice = (prices.min { $0.price < $1.price }?.price ?? 0) - 0.05
        let maxPrice = (prices.max { $0.price < $1.price }?.price ?? 0.5) + 0.05
        return max(0, minPrice)...maxPrice
    }
    
    private func formatHour(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:00"
        return formatter.string(from: date)
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Precios durante el día")
                .font(.headline)
                .padding(.horizontal)
            
            Chart {
                ForEach(prices) { price in
                    LineMark(
                        x: .value("Hora", price.hour),
                        y: .value("Precio", price.price)
                    )
                    .foregroundStyle(Color.blue)
                    .lineStyle(StrokeStyle(lineWidth: 3))
                    
                    PointMark(
                        x: .value("Hora", price.hour),
                        y: .value("Precio", price.price)
                    )
                    .foregroundStyle(
                        price.price == highestPrice?.price ? Color.red :
                        price.price == lowestPrice?.price ? Color.green : Color.blue
                    )
                    .symbolSize(
                        price.price == highestPrice?.price || price.price == lowestPrice?.price ? 120 : 40
                    )
                }
            }
            .chartXAxis {
                AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatHour(date))
                        }
                    }
                }
            }
            .chartYScale(domain: priceRange)
            .chartYAxis {
                AxisMarks { value in
                    AxisGridLine()
                    AxisValueLabel() {
                        let doubleValue = value.as(Double.self) ?? 0
                        Text("\(String(format: "%.2f", doubleValue))€")
                    }
                }
            }
            .frame(height: 250)
            .padding()
            
            HStack {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.green)
                    .frame(width: 15, height: 15)
                Text("Precio más bajo")
                
                Spacer()
                
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.red)
                    .frame(width: 15, height: 15)
                Text("Precio más alto")
            }
            .padding(.horizontal)
            .font(.caption)
        }
        .padding(.vertical)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

#Preview {
    // Create mock data for preview
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())
    var prices: [ElectricityPrice] = []
    
    for hour in 0..<24 {
        if let date = calendar.date(byAdding: .hour, value: hour, to: today) {
            let price = Double.random(in: 0.08...0.35)
            let priceData = ElectricityPrice(hour: date, price: price)
            prices.append(priceData)
        }
    }
    
    let lowestPrice = prices.min { $0.price < $1.price }
    let highestPrice = prices.max { $0.price < $1.price }
    
    return PriceChartView(prices: prices, lowestPrice: lowestPrice, highestPrice: highestPrice)
        .padding()
        .background(Color(.systemGroupedBackground))
} 