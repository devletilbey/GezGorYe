import CoreLocation

struct City: Identifiable, Codable, Hashable {
    let name: String
    let center: GeoCoordinate
    let notes: [String]
    let localFoods: [String]
    let pointsOfInterest: [POI]

    var id: String { name }
    var location: CLLocationCoordinate2D { center.location }
}

struct GeoCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double

    var location: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct POI: Identifiable, Codable, Hashable {
    let name: String
    let category: POICategory
    let coordinate: GeoCoordinate
    let shortDescription: String
    let recommendedVisitMinutes: Int

    var id: String { "\(name)-\(category.rawValue)" }
}

enum POICategory: String, Codable, CaseIterable, Hashable, Identifiable {
    case historical
    case waterfall
    case nature
    case food
    case museum

    var id: String { rawValue }

    var title: String {
        switch self {
        case .historical: return "Tarihi"
        case .waterfall: return "Selale"
        case .nature: return "Doga"
        case .food: return "Lezzet"
        case .museum: return "Muze"
        }
    }

    var symbol: String {
        switch self {
        case .historical: return "building.columns.fill"
        case .waterfall: return "drop.fill"
        case .nature: return "leaf.fill"
        case .food: return "fork.knife"
        case .museum: return "building.2.fill"
        }
    }
}
