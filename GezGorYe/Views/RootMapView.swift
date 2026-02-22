import MapKit
import SwiftUI
import UIKit

struct RootMapView: View {
    @StateObject private var viewModel = TravelGuideViewModel()
    @StateObject private var settings = AppSettings()

    var body: some View {
        DarkAppleMapView(
            region: $viewModel.cameraRegion,
            cities: viewModel.cities,
            selectedCity: viewModel.selectedCity,
            pois: viewModel.filteredPOIs,
            routeCoordinates: viewModel.routeCoordinates,
            accentColor: UIColor(settings.theme.palette.accent),
            secondaryAccentColor: UIColor(settings.theme.palette.secondaryAccent),
            onSelectCity: { city in
                viewModel.selectCity(city)
            }
        )
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
