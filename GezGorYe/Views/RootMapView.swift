import MapKit
import SwiftUI

struct RootMapView: View {
    @StateObject private var viewModel = TravelGuideViewModel()
    @StateObject private var settings = AppSettings()

    var body: some View {
        Map(position: $viewModel.cameraPosition, interactionModes: .all) {
            ForEach(viewModel.cities) { city in
                Annotation(city.name, coordinate: city.location) {
                    CityPin(
                        city: city,
                        isSelected: viewModel.selectedCity?.id == city.id,
                        accent: settings.theme.palette.accent
                    ) {
                        viewModel.selectCity(city)
                    }
                }
            }

            if let city = viewModel.selectedCity {
                Annotation("Merkez", coordinate: city.location) {
                    Image(systemName: "scope")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(settings.theme.palette.accent, in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.55), lineWidth: 1))
                }

                ForEach(viewModel.filteredPOIs) { poi in
                    Marker(poi.name, systemImage: poi.category.symbol, coordinate: poi.coordinate.location)
                        .tint(settings.theme.palette.secondaryAccent)
                }

                if viewModel.routeCoordinates.count > 1 {
                    MapPolyline(coordinates: viewModel.routeCoordinates)
                        .stroke(
                            LinearGradient(
                                colors: [settings.theme.palette.secondaryAccent, settings.theme.palette.accent],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round, dash: [6, 5])
                        )
                }
            }
        }
        .mapStyle(settings.mapStyleOption.mapStyle)
        .mapControlVisibility(.visible)
        .mapControls {
            MapCompass()
            MapScaleView()
            MapPitchToggle()
            MapUserLocationButton()
        }
        .ignoresSafeArea()
        .alert("Veri Yüklenemedi", isPresented: .constant(viewModel.loadingError != nil)) {
            Button("Tamam") {
                viewModel.loadingError = nil
            }
        } message: {
            Text(viewModel.loadingError ?? "")
        }
    }
}

private struct CityPin: View {
    let city: City
    let isSelected: Bool
    let accent: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: isSelected ? "mappin.circle.fill" : "mappin.circle")
                    .font(.title3)
                Text(city.name)
                    .font(.caption2.weight(.bold))
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 7)
            .foregroundStyle(isSelected ? .white : .black)
            .background(
                isSelected ? accent : Color.white,
                in: RoundedRectangle(cornerRadius: 12, style: .continuous)
            )
            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    RootMapView()
}
