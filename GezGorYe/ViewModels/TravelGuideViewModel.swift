import Foundation
import MapKit
import SwiftUI

@MainActor
final class TravelGuideViewModel: ObservableObject {
    @Published var cities: [City] = []
    @Published var selectedCity: City?
    @Published var selectedCategories = Set(POICategory.allCases)
    @Published var cameraPosition: MapCameraPosition
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

        self.cameraPosition = .region(Self.turkeyRegion)
        loadCities()
    }

    var mapCities: [City] {
        selectedCity == nil ? cities : []
    }

    func selectCity(_ city: City) {
        selectedCity = city
        selectedCategories = Set(POICategory.allCases)
        cameraPosition = .region(
            MKCoordinateRegion(
                center: city.location,
                span: MKCoordinateSpan(latitudeDelta: 0.45, longitudeDelta: 0.45)
            )
        )
        updateDerivedData()
    }

    func resetToTurkey() {
        selectedCity = nil
        selectedCategories = Set(POICategory.allCases)
        cameraPosition = .region(Self.turkeyRegion)
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
            cities = loaded.sorted {
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

        let pois = city.pointsOfInterest.filter { selectedCategories.contains($0.category) }
        filteredPOIs = pois

        let optimized = optimizer.buildFastestPlan(start: city.center, pois: pois)
        routePlan = optimized

        let stops = optimized.orderedStops.map { $0.poi.coordinate.location }
        routeCoordinates = [city.location] + stops
    }

    private static let emptyRoutePlan = RoutePlan(orderedStops: [], totalDistanceKm: 0, totalMinutes: 0)

    private static let turkeyRegion = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 39.1, longitude: 35.2),
        span: MKCoordinateSpan(latitudeDelta: 8.5, longitudeDelta: 7.5)
    )
}
