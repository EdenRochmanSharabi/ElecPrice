import Foundation
import Combine

class ElectricityService: ObservableObject {
    @Published var dailyData = DailyPriceData()
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var dataSource: String = "Estimado" // "Web", "API", or "Estimado"
    @Published var selectedCity: City?
    @Published var isCitySelected = false
    @Published var isUsingMockData = false // Nuevo flag para indicar si se están usando datos estimados
    
    private var cancellables = Set<AnyCancellable>()
    
    private let userDefaultsCityKey = "selectedCity"
    
    // Common Spanish cities
    let availableCities = [
        City(name: "Madrid"),
        City(name: "Barcelona"),
        City(name: "Valencia"),
        City(name: "Sevilla"),
        City(name: "Zaragoza"),
        City(name: "Málaga"),
        City(name: "Murcia"),
        City(name: "Palma de Mallorca"),
        City(name: "Las Palmas de Gran Canaria"),
        City(name: "Bilbao"),
        City(name: "Alicante"),
        City(name: "Córdoba"),
        City(name: "Valladolid"),
        City(name: "Vigo"),
        City(name: "Gijón"),
        City(name: "Granada"),
        City(name: "A Coruña"),
        City(name: "Sanlúcar de Barrameda")
    ]
    
    init() {
        loadSelectedCity()
        if isCitySelected {
            fetchPriceData()
        }
    }
    
    func loadSelectedCity() {
        if let savedData = UserDefaults.standard.data(forKey: userDefaultsCityKey),
           let decodedCity = try? JSONDecoder().decode(City.self, from: savedData) {
            selectedCity = decodedCity
            isCitySelected = true
        }
    }
    
    func saveSelectedCity(_ city: City) {
        selectedCity = city
        isCitySelected = true
        
        if let encodedData = try? JSONEncoder().encode(city) {
            UserDefaults.standard.set(encodedData, forKey: userDefaultsCityKey)
        }
        
        fetchPriceData()
    }
    
    func fetchPriceData() {
        isLoading = true
        errorMessage = nil
        
        // First try to scrape from the website using direct HTML parsing
        fetchWebPriceData()
    }
    
    // Web scraping method to get prices from tarifaluzhora.es without using SwiftSoup
    private func fetchWebPriceData() {
        let urlString = "https://tarifaluzhora.es/"
        
        guard let url = URL(string: urlString) else {
            // Fall back to API if URL creation fails
            fetchRealPriceData()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTaskPublisher(for: request)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                switch completion {
                case .finished:
                    break
                case .failure:
                    // Fall back to the REE API if web scraping fails
                    self.fetchRealPriceData()
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                
                if let htmlString = String(data: data, encoding: .utf8) {
                    // Store the prices we find
                    var prices: [ElectricityPrice] = []
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    
                    // Method 1: Look for the formatted hourly prices section
                    // Expected format is like "00:00 - 01:00" followed by a price like "0.1072 €/kWh"
                    for hour in 0..<24 {
                        let hourFormat: String
                        if hour < 23 {
                            hourFormat = String(format: "%02d:00 - %02d:00", hour, hour + 1)
                        } else {
                            hourFormat = "23:00 - 24:00"
                        }
                        
                        if let hourRange = htmlString.range(of: hourFormat),
                           let priceKwhRange = htmlString[hourRange.upperBound...].range(of: "€/kWh") {
                            // Look for the price between the hour and "€/kWh"
                            let searchStart = hourRange.upperBound
                            let searchEnd = priceKwhRange.upperBound
                            let searchText = String(htmlString[searchStart..<searchEnd])
                            
                            if let priceValue = self.extractPrice(from: searchText) {
                                if let date = calendar.date(byAdding: .hour, value: hour, to: today) {
                                    let priceData = ElectricityPrice(hour: date, price: priceValue)
                                    prices.append(priceData)
                                }
                            }
                        }
                    }
                    
                    // Method 2: If the first method failed, try to find specific patterns in the page
                    if prices.isEmpty {
                        // Check if we have a price table section
                        if let tableStart = htmlString.range(of: "Precio del kWh de luz por hora") {
                            // Create a specific list of hourly patterns to search for
                            let hourPatterns = [
                                "00:00 - 01:00", "01:00 - 02:00", "02:00 - 03:00", "03:00 - 04:00",
                                "04:00 - 05:00", "05:00 - 06:00", "06:00 - 07:00", "07:00 - 08:00",
                                "08:00 - 09:00", "09:00 - 10:00", "10:00 - 11:00", "11:00 - 12:00",
                                "12:00 - 13:00", "13:00 - 14:00", "14:00 - 15:00", "15:00 - 16:00",
                                "16:00 - 17:00", "17:00 - 18:00", "18:00 - 19:00", "19:00 - 20:00",
                                "20:00 - 21:00", "21:00 - 22:00", "22:00 - 23:00", "23:00 - 24:00"
                            ]
                            
                            // Only search in the table section
                            let tableHTML = String(htmlString[tableStart.lowerBound...])
                            
                            for (hour, pattern) in hourPatterns.enumerated() {
                                // First, find the hour pattern
                                if let hourRange = tableHTML.range(of: pattern) {
                                    // After the hour, look for a price pattern
                                    let afterHour = tableHTML[hourRange.upperBound...]
                                    if let euroRange = afterHour.range(of: "€/kWh") {
                                        // Search in a limited range for the actual number
                                        let searchLimit = tableHTML.index(hourRange.upperBound, offsetBy: 100, limitedBy: euroRange.lowerBound) ?? euroRange.lowerBound
                                        let searchText = String(tableHTML[hourRange.upperBound..<searchLimit])
                                        
                                        if let price = extractPriceNearEuro(from: searchText) {
                                            if let date = calendar.date(byAdding: .hour, value: hour, to: today) {
                                                let priceData = ElectricityPrice(hour: date, price: price)
                                                prices.append(priceData)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                    // Method 3: Try to extract daily summary values if we still don't have hourly data
                    var lowestPrice: Double = 0
                    var highestPrice: Double = 0
                    var avgPrice: Double = 0
                    var lowestHour: Int = 0
                    var highestHour: Int = 0
                    
                    if let lowestRange = htmlString.range(of: "Precio más bajo del día") {
                        // Try to extract the lowest price
                        if let hourRange = htmlString[lowestRange.upperBound...].range(of: "-"),
                           let hourText = htmlString[lowestRange.upperBound..<hourRange.lowerBound].range(of: #"\d+"#, options: .regularExpression),
                           let hour = Int(htmlString[hourText]) {
                            lowestHour = hour
                        }
                        
                        // Look for the lowest price value
                        if let priceRange = htmlString[lowestRange.upperBound...].range(of: "€/kWh", options: .backwards),
                           let searchStartIndex = htmlString.index(priceRange.lowerBound, offsetBy: -10, limitedBy: lowestRange.upperBound) {
                            let searchText = String(htmlString[searchStartIndex..<priceRange.lowerBound])
                            if let price = self.extractPrice(from: searchText) {
                                lowestPrice = price
                            }
                        }
                    }
                    
                    if let highestRange = htmlString.range(of: "Precio más alto del día") {
                        // Try to extract the highest price hour
                        if let hourRange = htmlString[highestRange.upperBound...].range(of: "-"),
                           let hourText = htmlString[highestRange.upperBound..<hourRange.lowerBound].range(of: #"\d+"#, options: .regularExpression),
                           let hour = Int(htmlString[hourText]) {
                            highestHour = hour
                        }
                        
                        // Look for the highest price value
                        if let priceRange = htmlString[highestRange.upperBound...].range(of: "€/kWh", options: .backwards),
                           let searchStartIndex = htmlString.index(priceRange.lowerBound, offsetBy: -10, limitedBy: highestRange.upperBound) {
                            let searchText = String(htmlString[searchStartIndex..<priceRange.lowerBound])
                            if let price = self.extractPrice(from: searchText) {
                                highestPrice = price
                            }
                        }
                    }
                    
                    // Try to find the average price
                    if let avgRange = htmlString.range(of: "Precio medio del día") {
                        if let priceRange = htmlString[avgRange.upperBound...].range(of: "€/kWh", options: .backwards),
                           let searchStartIndex = htmlString.index(priceRange.lowerBound, offsetBy: -10, limitedBy: avgRange.upperBound) {
                            let searchText = String(htmlString[searchStartIndex..<priceRange.lowerBound])
                            if let price = self.extractPrice(from: searchText) {
                                avgPrice = price
                            }
                        }
                    }
                    
                    // If we have summary data but no hourly prices, generate approximated hourly prices
                    if prices.isEmpty && (lowestPrice > 0 || highestPrice > 0 || avgPrice > 0) {
                        // If we have only average but no min/max, estimate a range
                        if lowestPrice == 0 && highestPrice == 0 && avgPrice > 0 {
                            lowestPrice = avgPrice * 0.6
                            highestPrice = avgPrice * 1.4
                        }
                        // If we have only one of min/max, estimate the other
                        else if lowestPrice > 0 && highestPrice == 0 {
                            highestPrice = lowestPrice * 2.5
                        }
                        else if highestPrice > 0 && lowestPrice == 0 {
                            lowestPrice = highestPrice * 0.4
                        }
                        
                        // Now create prices for each hour based on a typical daily pattern
                        for hour in 0..<24 {
                            if let date = calendar.date(byAdding: .hour, value: hour, to: today) {
                                let price: Double
                                
                                // Use known min/max hours if available
                                if hour == lowestHour && lowestPrice > 0 {
                                    price = lowestPrice
                                } else if hour == highestHour && highestPrice > 0 {
                                    price = highestPrice
                                } else {
                                    // Otherwise use a typical daily curve
                                    let range = highestPrice - lowestPrice
                                    switch hour {
                                    case 0..<7: // Night (lowest)
                                        price = lowestPrice + range * 0.1
                                    case 7..<10: // Morning (high)
                                        price = lowestPrice + range * 0.7
                                    case 10..<14: // Midday (medium)
                                        price = lowestPrice + range * 0.4
                                    case 14..<18: // Afternoon (low)
                                        price = lowestPrice + range * 0.2
                                    case 18..<22: // Evening (highest)
                                        price = highestPrice
                                    case 22..<24: // Late evening (medium-high)
                                        price = lowestPrice + range * 0.6
                                    default:
                                        price = avgPrice > 0 ? avgPrice : (lowestPrice + highestPrice) / 2
                                    }
                                }
                                
                                let priceData = ElectricityPrice(hour: date, price: price)
                                prices.append(priceData)
                            }
                        }
                    }
                    
                    // If we have prices, update the UI
                    if !prices.isEmpty {
                        // Sort prices by hour
                        prices.sort { $0.hour < $1.hour }
                        self.dailyData.prices = prices
                        self.isLoading = false
                        self.errorMessage = nil
                        self.dataSource = "Web"
                        self.isUsingMockData = false
                    } else {
                        // If we couldn't parse any prices, try the API
                        self.fetchRealPriceData()
                    }
                } else {
                    // If we couldn't convert the data to a string, fall back to the API
                    self.fetchRealPriceData()
                }
            })
            .store(in: &cancellables)
    }
    
    // Extract price from text like "0.1072 €/kWh"
    private func extractPrice(from text: String) -> Double? {
        // Try different patterns to extract prices
        
        // Pattern 1: Find numbers like 0.1072 or 0,1072
        let decimalPattern = #"(\d+[\.,]\d+)"#
        if let range = text.range(of: decimalPattern, options: .regularExpression) {
            let priceText = String(text[range])
            // Replace comma with period if needed
            let normalizedPrice = priceText.replacingOccurrences(of: ",", with: ".")
            return Double(normalizedPrice)
        }
        
        return nil
    }
    
    // Extract price that appears before "€/kWh"
    private func extractPriceNearEuro(from text: String) -> Double? {
        // Extract prices specifically around the Euro symbol
        let euroPattern = #"(\d+[\.,]\d+)\s*€\/kWh"#
        if let range = text.range(of: euroPattern, options: .regularExpression) {
            let matchText = String(text[range])
            // Extract just the number part
            let decimalPattern = #"(\d+[\.,]\d+)"#
            if let numRange = matchText.range(of: decimalPattern, options: .regularExpression) {
                let priceText = String(matchText[numRange])
                // Replace comma with period if needed
                let normalizedPrice = priceText.replacingOccurrences(of: ",", with: ".")
                return Double(normalizedPrice)
            }
        }
        
        // Alternative pattern for cases where format is different
        if let euroRange = text.range(of: "€/kWh") {
            // Look for a number before the €/kWh
            let beforeEuro = text[..<euroRange.lowerBound]
            let decimalPattern = #"(\d+[\.,]\d+)"#
            if let numRange = beforeEuro.range(of: decimalPattern, options: [.regularExpression, .backwards]) {
                let priceText = String(beforeEuro[numRange])
                // Replace comma with period if needed
                let normalizedPrice = priceText.replacingOccurrences(of: ",", with: ".")
                return Double(normalizedPrice)
            }
        }
        
        return nil
    }
    
    // REE API integration for Spanish electricity prices
    private func fetchRealPriceData() {
        // Create today's date in the format required by the API
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let today = dateFormatter.string(from: Date())
        
        let urlString = "https://apidatos.ree.es/en/datos/mercados/precios-mercados-tiempo-real?start_date=\(today)T00:00&end_date=\(today)T23:59&time_trunc=hour"
        
        guard let url = URL(string: urlString) else {
            self.errorMessage = "URL incorrecta"
            self.isLoading = false
            // Fall back to mock data
            self.generateMockData()
            return
        }
        
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\.data)
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                guard let self = self else { return }
                
                self.isLoading = false
                
                switch completion {
                case .finished:
                    break
                case .failure(let error):
                    self.errorMessage = "Error al cargar los datos: \(error.localizedDescription)"
                    // Fall back to mock data if API fails
                    self.generateMockData()
                }
            }, receiveValue: { [weak self] data in
                guard let self = self else { return }
                
                // Try to parse the REE API data format
                do {
                    if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let included = json["included"] as? [[String: Any]],
                       let firstItem = included.first,
                       let attributes = firstItem["attributes"] as? [String: Any],
                       let values = attributes["values"] as? [[String: Any]] {
                        
                        var prices: [ElectricityPrice] = []
                        let dateFormatter = ISO8601DateFormatter()
                        
                        for value in values {
                            if let priceValue = value["value"] as? Double,
                               let dateString = value["datetime"] as? String,
                               let date = dateFormatter.date(from: dateString) {
                                
                                // Price is in €/MWh, convert to €/kWh
                                let priceInKwh = priceValue / 1000
                                let priceData = ElectricityPrice(hour: date, price: priceInKwh)
                                prices.append(priceData)
                            }
                        }
                        
                        if prices.isEmpty {
                            self.errorMessage = "No se encontraron datos de precios"
                            self.generateMockData()
                        } else {
                            // Sort prices by hour
                            prices.sort { $0.hour < $1.hour }
                            self.dailyData.prices = prices
                            self.errorMessage = nil
                            self.dataSource = "API"
                            self.isUsingMockData = false
                        }
                    } else {
                        self.errorMessage = "Formato de datos inesperado"
                        self.generateMockData()
                    }
                } catch {
                    self.errorMessage = "Error al procesar los datos: \(error.localizedDescription)"
                    self.generateMockData()
                }
            })
            .store(in: &cancellables)
    }
    
    // Fallback to mock data if API fails
    private func generateMockData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var prices: [ElectricityPrice] = []
        
        // Spanish electricity prices tend to be higher in the evenings and lower at night
        for hour in 0..<24 {
            if let date = calendar.date(byAdding: .hour, value: hour, to: today) {
                // Create a realistic price pattern (lower at night, higher in evening)
                var price: Double
                
                switch hour {
                case 0..<7:
                    // Night hours (cheapest)
                    price = Double.random(in: 0.08...0.12)
                case 7..<10, 14..<17:
                    // Morning and afternoon (medium)
                    price = Double.random(in: 0.15...0.20)
                case 10..<14:
                    // Mid-day (high)
                    price = Double.random(in: 0.18...0.23)
                case 17..<22:
                    // Evening peak (highest)
                    price = Double.random(in: 0.25...0.35)
                case 22..<24:
                    // Late evening (medium-high)
                    price = Double.random(in: 0.18...0.25)
                default:
                    price = 0.15
                }
                
                let priceData = ElectricityPrice(hour: date, price: price)
                prices.append(priceData)
            }
        }
        
        // Sort prices by hour
        prices.sort { $0.hour < $1.hour }
        
        self.dailyData.prices = prices
        self.dataSource = "Estimado"
        self.isUsingMockData = true // Marcamos que se están usando datos estimados
        
        // Si no hay un mensaje de error específico, añadimos un aviso sobre los datos estimados
        if self.errorMessage == nil {
            self.errorMessage = "AVISO: Usando precios estimados. Estos NO son precios reales de electricidad. Los datos reales no están disponibles en este momento."
        } else {
            // Si ya hay un error, añadimos el aviso sobre datos estimados
            self.errorMessage = self.errorMessage! + "\n\nSe muestran precios ESTIMADOS que NO son reales."
        }
        
        self.isLoading = false
    }
}

// Structure for legacy API response - kept for reference
struct PriceData: Codable {
    let date: String
    let hour: String
    let price: Double
    let units: String
} 