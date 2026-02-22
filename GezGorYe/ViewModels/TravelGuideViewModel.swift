import Foundation
import MapKit
import SwiftUI

@MainActor
final class TravelGuideViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var selectedCity: City?
    @Published var selectedCategories = Set(POICategory.allCases)
    @Published var cameraRegion: MKCoordinateRegion
    @Published var loadingError: String?
    @Published private(set) var filteredPOIs: [POI] = []
    @Published private(set) var routePlan: RoutePlan = RoutePlan(orderedStops: [], totalDistanceKm: 0, totalMinutes: 0)
    @Published private(set) var routeCoordinates: [CLLocationCoordinate2D] = []

    private let repository: CityRepositoryProtocol
    private let optimizer: RouteOptimizing

    init(
        repository: CityRepositoryProtocol = CityRepository(),
        optimizer: RouteOptimizing = RouteOptimizer()
    ) {
        self.repository = repository
        self.optimizer = optimizer

        self.cameraRegion = Self.turkeyRegion
        loadCities()
    }

    var mapCities: [City] {
        selectedCity == nil ? cities : []
    }

    func selectCity(_ city: City) {
        selectedCity = city
        selectedCategories = Set(POICategory.allCases)
        cameraRegion = MKCoordinateRegion(
            center: city.location,
            span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
        )
        updateDerivedData()
    }

    func resetToTurkey() {
        selectedCity = nil
        selectedCategories = Set(POICategory.allCases)
        cameraRegion = Self.turkeyRegion
        updateDerivedData()
    }

    func toggleCategory(_ category: POICategory) {
        if selectedCategories.contains(category) {
            if selectedCategories.count > 1 {
                selectedCategories.remove(category)
            }
        } else {
            selectedCategories.insert(category)
        }
        updateDerivedData()
    }

    private func loadCities() {
        do {
            let loaded = try repository.loadCities()
            let sanitized = loaded.map(Self.sanitizedCity)
            cities = sanitized.sorted {
                $0.name.folding(options: .diacriticInsensitive, locale: .current)
                    < $1.name.folding(options: .diacriticInsensitive, locale: .current)
            }
        } catch {
            loadingError = error.localizedDescription
        }
    }

    private func updateDerivedData() {
        guard let city = selectedCity else {
            filteredPOIs = []
            routePlan = Self.emptyRoutePlan
            routeCoordinates = []
            return
        }

        let pois = city.pointsOfInterest.filter {
            selectedCategories.contains($0.category) &&
                Self.isTravelRelevant($0, in: city)
        }
        filteredPOIs = pois

        let optimized = optimizer.buildFastestPlan(start: city.center, pois: pois)
        routePlan = optimized

        let stops = optimized.orderedStops.map { $0.poi.coordinate.location }
        routeCoordinates = [city.location] + stops
    }

    private static let emptyRoutePlan = RoutePlan(orderedStops: [], totalDistanceKm: 0, totalMinutes: 0)

    private static func sanitizedCity(_ city: City) -> City {
        let filtered = city.pointsOfInterest.filter { isTravelRelevant($0, in: city) }
        return City(
            name: city.name,
            center: city.center,
            notes: city.notes,
            localFoods: city.localFoods,
            pointsOfInterest: filtered
        )
    }

    private static func isTravelRelevant(_ poi: POI, in city: City) -> Bool {
        let rawName = poi.name.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = normalizedText(rawName)
        let description = normalizedText(poi.shortDescription)
        let combined = "\(name) \(description)"
        let cityName = normalizedText(city.name)

        if name == cityName {
            return false
        }

        let exactBlacklist: Set<String> = [
            "halic",
            "15 temmuz sehitler koprusu",
            "bogazici koprusu",
            "yavuz sultan selim koprusu",
            "osmangazi koprusu",
            "1915 canakkale koprusu",
            "nissibi koprusu",
            "yeni komurhan koprusu",
            "begendik koprusu"
        ]
        if exactBlacklist.contains(name) {
            return false
        }

        let nameBlacklists = [
            "15 temmuz sehitler koprusu",
            "bogazici koprusu",
            "yavuz sultan selim koprusu",
            "osmangazi koprusu",
            "1915 canakkale koprusu",
            "nissibi koprusu",
            "yeni komurhan koprusu",
            "begendik koprusu"
        ]
        if nameBlacklists.contains(where: { name.contains($0) }) {
            return false
        }

        if cityName == "istanbul" && name.contains("kopru") {
            let historicBridgeWhitelist = [
                "valens kemeri", "bizans su kemeri", "galata koprusu"
            ]
            if !historicBridgeWhitelist.contains(where: { name.contains($0) }) {
                return false
            }
        }

        let disallowedPatterns = [
            "baraj",
            "hidroelektrik santrali",
            " karayolu tüneli",
            " tüneli",
            " tuneli",
            "gold mine",
            " altın madeni",
            " türkiye'de akarsu",
            "river in",
            " birinci köprü",
            " üçüncü köprü",
            "asya'yı avrupa'ya bağlayan",
            "gergin eğik askılı"
        ]
        if disallowedPatterns.contains(where: { combined.contains($0) }) {
            return false
        }

        return true
    }

    private static func normalizedText(_ value: String) -> String {
        let lowered = value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: Locale(identifier: "tr_TR"))
            .replacingOccurrences(of: "ı", with: "i")
        let mapped = lowered
            .replacingOccurrences(of: "ç", with: "c")
            .replacingOccurrences(of: "ğ", with: "g")
            .replacingOccurrences(of: "ö", with: "o")
            .replacingOccurrences(of: "ş", with: "s")
            .replacingOccurrences(of: "ü", with: "u")
        return mapped
            .replacingOccurrences(of: "[^a-z0-9 ]+", with: " ", options: .regularExpression)
            .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static let turkeyRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.1, longitude: 35.2),
        span: MKCoordinateSpan(latitudeDelta: 8.5, longitudeDelta: 7.5)
    )
}
