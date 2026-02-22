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
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                view.transform = CGAffineTransform(scaleX: 1.08, y: 1.08)
            }

            guard let annotation = view.annotation as? CityAnnotation else { return }
            parent.onSelectCity(annotation.city)
        }

        func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
            UIView.animate(withDuration: 0.18, delay: 0, options: [.curveEaseOut]) {
                view.transform = .identity
            }
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

            if let cluster = annotation as? MKClusterAnnotation {
                let identifier = "cluster"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                view.collisionMode = .circle
                view.displayPriority = .required
                view.centerOffset = CGPoint(x: 0, y: -2)
                view.image = PremiumMapIconFactory.cluster(
                    count: cluster.memberAnnotations.count,
                    accent: parent.accentColor
                )
                return view
            }

            if let cityAnnotation = annotation as? CityAnnotation {
                let identifier = "city"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                view.displayPriority = cityAnnotation.isSelected ? .required : .defaultHigh
                view.collisionMode = .circle
                view.clusteringIdentifier = "city"
                view.centerOffset = CGPoint(x: 0, y: -4)
                view.image = PremiumMapIconFactory.city(
                    selected: cityAnnotation.isSelected,
                    accent: parent.accentColor
                )
                return view
            }

            if annotation is CenterAnnotation {
                let identifier = "center"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = false
                view.displayPriority = .required
                view.collisionMode = .circle
                view.centerOffset = CGPoint(x: 0, y: -4)
                view.image = PremiumMapIconFactory.center(accent: parent.accentColor)
                return view
            }

            if let poiAnnotation = annotation as? POIAnnotation {
                let identifier = "poi"
                let view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier)
                    ?? MKAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view.annotation = annotation
                view.canShowCallout = true
                view.displayPriority = .defaultHigh
                view.collisionMode = .circle
                view.clusteringIdentifier = nil
                view.centerOffset = CGPoint(x: 0, y: -4)
                view.image = PremiumMapIconFactory.poi(
                    symbol: poiAnnotation.poi.category.symbol,
                    tint: poiAnnotation.poi.category.mapIconTint,
                    accent: parent.secondaryAccentColor
                )

                let detail = UILabel()
                detail.numberOfLines = 2
                detail.font = .systemFont(ofSize: 12, weight: .medium)
                detail.textColor = .secondaryLabel
                detail.text = "\(poiAnnotation.poi.recommendedVisitMinutes) dk • \(poiAnnotation.poi.shortDescription)"
                detail.preferredMaxLayoutWidth = 220
                view.detailCalloutAccessoryView = detail
                return view
            }

            return nil
        }
    }
}

private enum PremiumMapIconFactory {
    private static var cache: [String: UIImage] = [:]

    static func city(selected: Bool, accent: UIColor) -> UIImage {
        let key = "city-\(selected)-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 34, height: 42)) { rect in
            let pinRect = CGRect(x: 4, y: 2, width: 26, height: 34)
            let headRect = CGRect(x: 4, y: 2, width: 26, height: 26)

            UIColor.black.withAlphaComponent(selected ? 0.35 : 0.25).setFill()
            UIBezierPath(ovalIn: headRect.insetBy(dx: -1, dy: -1)).fill()

            let pointerPath = UIBezierPath()
            pointerPath.move(to: CGPoint(x: rect.midX, y: 38))
            pointerPath.addLine(to: CGPoint(x: rect.midX - 5.5, y: 24))
            pointerPath.addLine(to: CGPoint(x: rect.midX + 5.5, y: 24))
            pointerPath.close()
            (selected ? accent : UIColor(white: 0.94, alpha: 0.96)).setFill()
            pointerPath.fill()

            let headColor = selected ? accent : UIColor(white: 0.97, alpha: 0.97)
            headColor.setFill()
            UIBezierPath(ovalIn: headRect).fill()

            UIColor.white.withAlphaComponent(selected ? 0.34 : 0.65).setStroke()
            UIBezierPath(ovalIn: headRect).stroke(lineWidth: 1.2)

            let innerRect = headRect.insetBy(dx: 5, dy: 5)
            UIColor.black.withAlphaComponent(selected ? 0.12 : 0.06).setFill()
            UIBezierPath(ovalIn: innerRect).fill()

            let symbolName = selected ? "sparkles" : "building.2.crop.circle"
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            let symbol = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
                .withTintColor(selected ? .white : UIColor(white: 0.12, alpha: 1), renderingMode: .alwaysOriginal)
            let symbolRect = CGRect(x: innerRect.midX - 7, y: innerRect.midY - 7, width: 14, height: 14)
            symbol?.draw(in: symbolRect)

            if selected {
                UIColor.white.withAlphaComponent(0.32).setStroke()
                UIBezierPath(ovalIn: headRect.insetBy(dx: -2.5, dy: -2.5)).stroke(lineWidth: 1.4)
            }

            _ = pinRect
        }

        cache[key] = image
        return image
    }

    static func center(accent: UIColor) -> UIImage {
        let key = "center-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 36, height: 36)) { rect in
            UIColor.black.withAlphaComponent(0.32).setFill()
            UIBezierPath(ovalIn: rect.insetBy(dx: 2, dy: 2)).fill()

            accent.withAlphaComponent(0.95).setStroke()
            UIBezierPath(ovalIn: rect.insetBy(dx: 5, dy: 5)).stroke(lineWidth: 2.4)

            UIColor.white.withAlphaComponent(0.9).setStroke()
            UIBezierPath(ovalIn: rect.insetBy(dx: 11, dy: 11)).stroke(lineWidth: 2)

            let ctx = UIGraphicsGetCurrentContext()
            ctx?.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            ctx?.setLineWidth(1.5)
            ctx?.move(to: CGPoint(x: rect.midX, y: 2))
            ctx?.addLine(to: CGPoint(x: rect.midX, y: 9))
            ctx?.move(to: CGPoint(x: rect.midX, y: rect.maxY - 2))
            ctx?.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 9))
            ctx?.move(to: CGPoint(x: 2, y: rect.midY))
            ctx?.addLine(to: CGPoint(x: 9, y: rect.midY))
            ctx?.move(to: CGPoint(x: rect.maxX - 2, y: rect.midY))
            ctx?.addLine(to: CGPoint(x: rect.maxX - 9, y: rect.midY))
            ctx?.strokePath()
        }

        cache[key] = image
        return image
    }

    static func poi(symbol: String, tint: UIColor, accent: UIColor) -> UIImage {
        let key = "poi-\(symbol)-\(tint.cacheKey)-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 30, height: 38)) { rect in
            let headRect = CGRect(x: 3, y: 2, width: 24, height: 24)

            UIColor.black.withAlphaComponent(0.28).setFill()
            UIBezierPath(ovalIn: headRect.insetBy(dx: -1, dy: -1)).fill()

            let pointer = UIBezierPath()
            pointer.move(to: CGPoint(x: rect.midX, y: 34))
            pointer.addLine(to: CGPoint(x: rect.midX - 4.6, y: 22))
            pointer.addLine(to: CGPoint(x: rect.midX + 4.6, y: 22))
            pointer.close()
            tint.withAlphaComponent(0.95).setFill()
            pointer.fill()

            tint.withAlphaComponent(0.96).setFill()
            UIBezierPath(ovalIn: headRect).fill()

            UIColor.white.withAlphaComponent(0.75).setStroke()
            UIBezierPath(ovalIn: headRect).stroke(lineWidth: 1)

            let inner = headRect.insetBy(dx: 4.5, dy: 4.5)
            UIColor.white.withAlphaComponent(0.14).setFill()
            UIBezierPath(ovalIn: inner).fill()

            let config = UIImage.SymbolConfiguration(pointSize: 10.5, weight: .bold)
            let symbolImage = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            symbolImage?.draw(in: CGRect(x: inner.midX - 6, y: inner.midY - 6, width: 12, height: 12))

            if symbol == "fork.knife" {
                accent.withAlphaComponent(0.25).setStroke()
                UIBezierPath(ovalIn: headRect.insetBy(dx: -2, dy: -2)).stroke(lineWidth: 1.2)
            }
        }

        cache[key] = image
        return image
    }

    static func cluster(count: Int, accent: UIColor) -> UIImage {
        let key = "cluster-\(min(count, 99))-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 40, height: 40)) { rect in
            let backRect = rect.insetBy(dx: 7, dy: 7)
            UIColor.black.withAlphaComponent(0.3).setFill()
            UIBezierPath(ovalIn: backRect.offsetBy(dx: 2, dy: 2)).fill()

            accent.withAlphaComponent(0.32).setFill()
            UIBezierPath(ovalIn: backRect.offsetBy(dx: -2, dy: -2)).fill()

            UIColor(white: 0.08, alpha: 0.9).setFill()
            UIBezierPath(ovalIn: backRect).fill()

            UIColor.white.withAlphaComponent(0.18).setStroke()
            UIBezierPath(ovalIn: backRect).stroke(lineWidth: 1.2)

            let text = count > 99 ? "99+" : "\(count)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: count > 9 ? 12 : 13, weight: .bold),
                .foregroundColor: UIColor.white
            ]
            let textSize = (text as NSString).size(withAttributes: attrs)
            let textRect = CGRect(
                x: rect.midX - textSize.width / 2,
                y: rect.midY - textSize.height / 2 - 0.5,
                width: textSize.width,
                height: textSize.height
            )
            (text as NSString).draw(in: textRect, withAttributes: attrs)
        }

        cache[key] = image
        return image
    }

    private static func render(size: CGSize, _ drawing: (CGRect) -> Void) -> UIImage {
        let format = UIGraphicsImageRendererFormat.default()
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { _ in
            drawing(CGRect(origin: .zero, size: size))
        }
    }
}

private extension UIColor {
    var cacheKey: String {
        guard let comps = cgColor.components else { return "0" }
        let vals = comps.map { Int(($0 * 255).rounded()) }
        return vals.map(String.init).joined(separator: "-")
    }
}

private extension UIBezierPath {
    func stroke(lineWidth: CGFloat) {
        self.lineWidth = lineWidth
        stroke()
    }
}

private extension POICategory {
    var mapIconTint: UIColor {
        switch self {
        case .historical:
            return UIColor(red: 0.82, green: 0.63, blue: 0.34, alpha: 1)
        case .waterfall:
            return UIColor(red: 0.18, green: 0.73, blue: 0.98, alpha: 1)
        case .nature:
            return UIColor(red: 0.34, green: 0.82, blue: 0.47, alpha: 1)
        case .food:
            return UIColor(red: 1.00, green: 0.60, blue: 0.20, alpha: 1)
        case .museum:
            return UIColor(red: 0.62, green: 0.67, blue: 0.98, alpha: 1)
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
