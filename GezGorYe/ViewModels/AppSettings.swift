import MapKit
import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case alpine
    case graphite
    case sunset

    var id: String { rawValue }

    var title: String {
        switch self {
        case .alpine: return "Alpine"
        case .graphite: return "Graphite"
        case .sunset: return "Sunset"
        }
    }

    var palette: ThemePalette {
        switch self {
        case .alpine:
            return ThemePalette(
                backgroundColors: [
                    Color(red: 0.03, green: 0.12, blue: 0.19),
                    Color(red: 0.02, green: 0.38, blue: 0.47),
                    Color(red: 0.09, green: 0.65, blue: 0.67)
                ],
                accent: Color(red: 0.38, green: 0.87, blue: 0.98),
                secondaryAccent: Color(red: 0.76, green: 0.95, blue: 1.0),
                cardOverlay: Color.white.opacity(0.12)
            )
        case .graphite:
            return ThemePalette(
                backgroundColors: [
                    Color(red: 0.07, green: 0.07, blue: 0.09),
                    Color(red: 0.13, green: 0.14, blue: 0.18),
                    Color(red: 0.20, green: 0.21, blue: 0.26)
                ],
                accent: Color(red: 0.82, green: 0.87, blue: 0.95),
                secondaryAccent: Color(red: 0.63, green: 0.69, blue: 0.78),
                cardOverlay: Color.white.opacity(0.09)
            )
        case .sunset:
            return ThemePalette(
                backgroundColors: [
                    Color(red: 0.22, green: 0.07, blue: 0.10),
                    Color(red: 0.43, green: 0.12, blue: 0.17),
                    Color(red: 0.88, green: 0.35, blue: 0.15)
                ],
                accent: Color(red: 1.0, green: 0.83, blue: 0.45),
                secondaryAccent: Color(red: 1.0, green: 0.92, blue: 0.77),
                cardOverlay: Color.white.opacity(0.11)
            )
        }
    }
}

struct ThemePalette {
    let backgroundColors: [Color]
    let accent: Color
    let secondaryAccent: Color
    let cardOverlay: Color

    var backgroundGradient: LinearGradient {
        LinearGradient(colors: backgroundColors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

enum AppleMapStyleOption: String, CaseIterable, Identifiable {
    case standard
    case hybrid
    case imagery

    var id: String { rawValue }

    var title: String {
        switch self {
        case .standard: return "Standart"
        case .hybrid: return "Hibrit"
        case .imagery: return "Uydu"
        }
    }

    var mapStyle: MapStyle {
        switch self {
        case .standard:
            return .standard(
                elevation: .realistic,
                emphasis: .automatic,
                showsTraffic: true
            )
        case .hybrid:
            return .hybrid(
                elevation: .realistic,
                showsTraffic: true
            )
        case .imagery:
            return .imagery(elevation: .realistic)
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var theme: AppTheme {
        didSet {
            defaults.set(theme.rawValue, forKey: Keys.theme)
        }
    }

    @Published var mapStyleOption: AppleMapStyleOption {
        didSet {
            defaults.set(mapStyleOption.rawValue, forKey: Keys.mapStyle)
        }
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        let themeRaw = defaults.string(forKey: Keys.theme)
        self.theme = AppTheme(rawValue: themeRaw ?? "") ?? .alpine

        let mapRaw = defaults.string(forKey: Keys.mapStyle)
        self.mapStyleOption = AppleMapStyleOption(rawValue: mapRaw ?? "") ?? .standard
    }

    private enum Keys {
        static let theme = "gezgorye.theme"
        static let mapStyle = "gezgorye.mapstyle"
    }
}
