import MapKit
import SwiftUI
import UIKit

struct RootMapView: View {
    @StateObject private var viewModel = TravelGuideViewModel()
    @StateObject private var settings = AppSettings()
    @State private var searchText = ""

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                DarkAppleMapView(
                    region: $viewModel.cameraRegion,
                    cities: viewModel.mapCities,
                    selectedCity: viewModel.selectedCity,
                    pois: viewModel.filteredPOIs,
                    routeCoordinates: viewModel.routeCoordinates,
                    accentColor: UIColor(settings.theme.palette.accent),
                    secondaryAccentColor: UIColor(settings.theme.palette.secondaryAccent),
                    onSelectCity: { city in
                        searchText = city.name
                        viewModel.selectCity(city)
                    }
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {
                    topHUD

                    if !searchResults.isEmpty && viewModel.selectedCity == nil {
                        searchResultsPanel
                    }

                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.top, 10)

                VStack(spacing: 0) {
                    Spacer()

                    if let selectedCity = viewModel.selectedCity {
                        cityBottomSheet(for: selectedCity, availableHeight: geometry.size.height)
                    } else {
                        mapOverviewPill
                            .padding(.horizontal, 12)
                            .padding(.bottom, 12)
                    }
                }
            }
            .alert("Veri Yüklenemedi", isPresented: .constant(viewModel.loadingError != nil)) {
                Button("Tamam") {
                    viewModel.loadingError = nil
                }
            } message: {
                Text(viewModel.loadingError ?? "")
            }
        }
    }

    private var topHUD: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "map.fill")
                    Text(viewModel.selectedCity?.name ?? "GezGorYe")
                        .lineLimit(1)
                }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(.black.opacity(0.42), in: Capsule())
                .overlay(Capsule().stroke(.white.opacity(0.12), lineWidth: 1))

                Spacer()

                Button {
                    searchText = ""
                    viewModel.resetToTurkey()
                } label: {
                    Image(systemName: "globe.europe.africa.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.black.opacity(0.42), in: Circle())
                        .overlay(Circle().stroke(.white.opacity(0.12), lineWidth: 1))
                }
                .accessibilityLabel("Türkiye görünümü")
            }

            HStack(spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.white.opacity(0.7))

                    TextField("81 il içinde ara", text: $searchText)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled()
                        .foregroundStyle(.white)

                    if !searchText.isEmpty {
                        Button {
                            searchText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.horizontal, 12)
                .frame(height: 46)
                .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(.white.opacity(0.12), lineWidth: 1)
                )

                if viewModel.selectedCity != nil {
                    Button {
                        searchText = ""
                        viewModel.resetToTurkey()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(.white)
                            .frame(width: 46, height: 46)
                            .background(.black.opacity(0.48), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16, style: .continuous)
                                    .stroke(.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .accessibilityLabel("Seçimi kaldır")
                }
            }
        }
    }

    private var searchResultsPanel: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                ForEach(Array(searchResults.prefix(12))) { city in
                    Button {
                        searchText = city.name
                        viewModel.selectCity(city)
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "location.circle.fill")
                                .foregroundStyle(settings.theme.palette.accent)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(city.name)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.white)
                                Text("\(city.pointsOfInterest.count) nokta  •  \(city.localFoods.count) lezzet")
                                    .font(.caption)
                                    .foregroundStyle(.white.opacity(0.68))
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(.white.opacity(0.04), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
        }
        .frame(maxHeight: 260)
        .background(.black.opacity(0.62), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private var mapOverviewPill: some View {
        HStack(spacing: 10) {
            Image(systemName: "sparkles")
                .foregroundStyle(settings.theme.palette.secondaryAccent)
            Text("81 il hazır. Haritadan seç veya üstten ara.")
                .font(.footnote.weight(.medium))
                .foregroundStyle(.white)
                .lineLimit(2)
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(.black.opacity(0.56), in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
    }

    private func cityBottomSheet(for city: City, availableHeight: CGFloat) -> some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(.white.opacity(0.24))
                .frame(width: 42, height: 5)
                .padding(.top, 8)

            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(city.name)
                        .font(.title3.weight(.bold))
                        .foregroundStyle(.white)
                    Text("\(viewModel.filteredPOIs.count) nokta • \(city.localFoods.count) lezzet • \(city.notes.count) not")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.75))
                }

                Spacer()

                Button {
                    searchText = ""
                    viewModel.resetToTurkey()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 34, height: 34)
                        .background(.white.opacity(0.08), in: Circle())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.top, 10)
            .padding(.bottom, 10)

            Divider()
                .overlay(.white.opacity(0.08))

            ScrollView(showsIndicators: false) {
                CityDetailView(city: city)
                    .environmentObject(viewModel)
                    .environmentObject(settings)
                    .padding(.horizontal, 14)
                    .padding(.top, 14)
                    .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: min(max(availableHeight * 0.56, 360), 560))
        .background(
            LinearGradient(
                colors: [
                    Color.black.opacity(0.92),
                    Color.black.opacity(0.78)
                ],
                startPoint: .top,
                endPoint: .bottom
            ),
            in: RoundedRectangle(cornerRadius: 24, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .stroke(.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal, 12)
        .padding(.bottom, 12)
        .shadow(color: .black.opacity(0.35), radius: 24, y: -8)
    }

    private var searchResults: [City] {
        let query = searchText.normalizedSearchQuery
        guard !query.isEmpty else { return [] }

        return viewModel.cities.filter { city in
            city.name.normalizedSearchQuery.contains(query)
        }
    }
}

private extension String {
    var normalizedSearchQuery: String {
        folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .replacingOccurrences(of: " ", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
}

private struct DarkAppleMapView: UIViewRepresentable {
    @Binding var region: MKCoordinateRegion
    let cities: [City]
    let selectedCity: City?
    let pois: [POI]
    let routeCoordinates: [CLLocationCoordinate2D]
    let accentColor: UIColor
    let secondaryAccentColor: UIColor
    let onSelectCity: (City) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView(frame: .zero)
        mapView.delegate = context.coordinator
        mapView.showsCompass = true
        mapView.showsScale = true
        mapView.showsUserLocation = true
        mapView.showsTraffic = true
        mapView.isRotateEnabled = true
        mapView.isPitchEnabled = true
        applyDarkMapStyle(to: mapView)

        mapView.setRegion(region, animated: false)
        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        applyDarkMapStyle(to: mapView)

        if !region.isApproximatelyEqual(to: mapView.region) {
            mapView.setRegion(region, animated: true)
        }

        let removableAnnotations = mapView.annotations.filter { !($0 is MKUserLocation) }
        mapView.removeAnnotations(removableAnnotations)

        var annotations: [MKAnnotation] = cities.map {
            CityAnnotation(city: $0, isSelected: selectedCity?.id == $0.id)
        }

        if let selectedCity {
            annotations.append(CenterAnnotation(coordinate: selectedCity.location))
            annotations.append(contentsOf: pois.map { POIAnnotation(poi: $0) })
        }

        mapView.addAnnotations(annotations)

        mapView.removeOverlays(mapView.overlays)
        if routeCoordinates.count > 1 {
            let line = MKPolyline(coordinates: routeCoordinates, count: routeCoordinates.count)
            mapView.addOverlay(line)
        }

        context.coordinator.parent = self
    }

    private func applyDarkMapStyle(to mapView: MKMapView) {
        mapView.overrideUserInterfaceStyle = .dark

        let config = MKStandardMapConfiguration(elevationStyle: .flat, emphasisStyle: .muted)
        config.showsTraffic = true
        mapView.preferredConfiguration = config
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: DarkAppleMapView

        init(_ parent: DarkAppleMapView) {
            self.parent = parent
        }

        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let annotation = view.annotation as? CityAnnotation else { return }
            parent.onSelectCity(annotation.city)
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            guard let polyline = overlay as? MKPolyline else {
                return MKOverlayRenderer(overlay: overlay)
            }

            let renderer = MKPolylineRenderer(polyline: polyline)
            renderer.strokeColor = parent.secondaryAccentColor
            renderer.lineWidth = 4
            renderer.lineCap = .round
            renderer.lineJoin = .round
            return renderer
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }

            if let cityAnnotation = annotation as? CityAnnotation {
                let identifier = "city"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                view.displayPriority = .required
                view.markerTintColor = cityAnnotation.isSelected ? parent.accentColor : UIColor.white
                view.glyphImage = UIImage(systemName: cityAnnotation.isSelected ? "mappin.circle.fill" : "mappin.circle")
                view.glyphTintColor = cityAnnotation.isSelected ? .white : .black
                return view
            }

            if annotation is CenterAnnotation {
                let identifier = "center"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                view.displayPriority = .required
                view.markerTintColor = parent.accentColor
                view.glyphImage = UIImage(systemName: "scope")
                view.glyphTintColor = .white
                return view
            }

            if let poiAnnotation = annotation as? POIAnnotation {
                let identifier = "poi"
                let view = (mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView)
                    ?? MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = true
                view.displayPriority = .defaultHigh
                view.markerTintColor = parent.secondaryAccentColor
                view.glyphImage = UIImage(systemName: poiAnnotation.poi.category.symbol)
                view.glyphTintColor = .black
                return view
            }

            return nil
        }
    }
}

private final class CityAnnotation: NSObject, MKAnnotation {
    let city: City
    let isSelected: Bool

    var coordinate: CLLocationCoordinate2D { city.location }
    var title: String? { city.name }

    init(city: City, isSelected: Bool) {
        self.city = city
        self.isSelected = isSelected
    }
}

private final class POIAnnotation: NSObject, MKAnnotation {
    let poi: POI

    var coordinate: CLLocationCoordinate2D { poi.coordinate.location }
    var title: String? { poi.name }
    var subtitle: String? { poi.shortDescription }

    init(poi: POI) {
        self.poi = poi
    }
}

private final class CenterAnnotation: NSObject, MKAnnotation {
    let coordinate: CLLocationCoordinate2D
    var title: String? { "Merkez" }

    init(coordinate: CLLocationCoordinate2D) {
        self.coordinate = coordinate
    }
}

private extension MKCoordinateRegion {
    func isApproximatelyEqual(to other: MKCoordinateRegion) -> Bool {
        abs(center.latitude - other.center.latitude) < 0.0005 &&
        abs(center.longitude - other.center.longitude) < 0.0005 &&
        abs(span.latitudeDelta - other.span.latitudeDelta) < 0.0005 &&
        abs(span.longitudeDelta - other.span.longitudeDelta) < 0.0005
    }
}

#Preview {
    RootMapView()
}
