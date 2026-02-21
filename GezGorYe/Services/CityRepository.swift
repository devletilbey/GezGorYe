import Foundation

protocol CityRepositoryProtocol {
    func loadCities() throws -> [City]
}

enum CityRepositoryError: LocalizedError {
    case dataMissing

    var errorDescription: String? {
        switch self {
        case .dataMissing:
            return "cities.json bulunamadi."
        }
    }
}

final class CityRepository: CityRepositoryProtocol {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    func loadCities() throws -> [City] {
        guard let url = bundle.url(forResource: "cities", withExtension: "json") else {
            throw CityRepositoryError.dataMissing
        }

        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode([City].self, from: data)
    }
}
