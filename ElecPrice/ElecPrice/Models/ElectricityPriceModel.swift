import Foundation

struct ElectricityPrice: Identifiable, Codable {
    let id = UUID()
    let hour: Date
    let price: Double
    
    enum CodingKeys: String, CodingKey {
        case hour
        case price
    }
}

struct City: Identifiable, Codable, Equatable {
    let id = UUID()
    let name: String
    
    static func == (lhs: City, rhs: City) -> Bool {
        return lhs.name == rhs.name
    }
}

struct DailyPriceData {
    var prices: [ElectricityPrice] = []
    var currentPrice: Double {
        let now = Date()
        let calendar = Calendar.current
        let currentHour = calendar.component(.hour, from: now)
        
        return prices.first { price in
            let hour = calendar.component(.hour, from: price.hour)
            return hour == currentHour
        }?.price ?? 0.0
    }
    
    var lowestPrice: ElectricityPrice? {
        prices.min { $0.price < $1.price }
    }
    
    var highestPrice: ElectricityPrice? {
        prices.max { $0.price < $1.price }
    }
    
    var averagePrice: Double {
        guard !prices.isEmpty else { return 0.0 }
        let total = prices.reduce(0.0) { $0 + $1.price }
        return total / Double(prices.count)
    }
} 