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
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.34
                view.layer.shadowRadius = 10
                view.layer.shadowOffset = CGSize(width: 0, height: 4)
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
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = cityAnnotation.isSelected ? 0.32 : 0.24
                view.layer.shadowRadius = cityAnnotation.isSelected ? 12 : 8
                view.layer.shadowOffset = CGSize(width: 0, height: 4)
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
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.28
                view.layer.shadowRadius = 12
                view.layer.shadowOffset = CGSize(width: 0, height: 4)
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
                view.layer.shadowColor = UIColor.black.cgColor
                view.layer.shadowOpacity = 0.26
                view.layer.shadowRadius = 9
                view.layer.shadowOffset = CGSize(width: 0, height: 4)

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

        let image = render(size: CGSize(width: 40, height: 52)) { rect in
            let ctx = UIGraphicsGetCurrentContext()
            let headRect = CGRect(x: 6, y: 4, width: 28, height: 28)
            let pinPath = cityPinPath(in: rect)

            UIColor.black.withAlphaComponent(0.20).setFill()
            UIBezierPath(ovalIn: CGRect(x: 10, y: 40, width: 20, height: 6)).fill()

            if selected {
                UIColor.white.withAlphaComponent(0.10).setFill()
                UIBezierPath(ovalIn: headRect.insetBy(dx: -5, dy: -5)).fill()
                drawGradientRing(
                    in: headRect.insetBy(dx: -4.5, dy: -4.5),
                    width: 2.0,
                    colors: [accent.withAlphaComponent(0.65), UIColor.white.withAlphaComponent(0.35)]
                )
            }

            let selectedTop = UIColor(red: 0.95, green: 0.84, blue: 0.56, alpha: 1)
            let selectedBottom = UIColor(red: 0.76, green: 0.58, blue: 0.23, alpha: 1)
            fill(path: pinPath, with: selected
                 ? [selectedTop, selectedBottom]
                 : [UIColor(white: 0.98, alpha: 0.98), UIColor(white: 0.86, alpha: 0.98)]
            , in: ctx)

            UIColor.white.withAlphaComponent(selected ? 0.42 : 0.72).setStroke()
            pinPath.stroke(lineWidth: 1.05)

            let inner = headRect.insetBy(dx: 5.2, dy: 5.2)
            fillCircle(
                inner,
                colors: selected
                    ? [UIColor(red: 0.22, green: 0.18, blue: 0.10, alpha: 0.95), UIColor(red: 0.09, green: 0.08, blue: 0.06, alpha: 0.95)]
                    : [UIColor.white.withAlphaComponent(0.92), UIColor(white: 0.90, alpha: 0.92)],
                in: ctx
            )

            if selected {
                drawGradientRing(
                    in: inner.insetBy(dx: -1.3, dy: -1.3),
                    width: 1.5,
                    colors: [selectedTop.withAlphaComponent(0.95), UIColor.white.withAlphaComponent(0.25)]
                )
            }

            UIColor.white.withAlphaComponent(selected ? 0.20 : 0.55).setStroke()
            UIBezierPath(ovalIn: inner).stroke(lineWidth: 0.8)

            let symbolName = "building.columns.fill"
            let symbolConfig = UIImage.SymbolConfiguration(pointSize: selected ? 11.5 : 10.5, weight: .bold)
            let symbol = UIImage(systemName: symbolName, withConfiguration: symbolConfig)?
                .withTintColor(selected ? selectedTop : UIColor(white: 0.14, alpha: 1), renderingMode: .alwaysOriginal)
            symbol?.draw(in: CGRect(x: inner.midX - 6.5, y: inner.midY - 6.5, width: 13, height: 13))

            UIColor.white.withAlphaComponent(selected ? 0.18 : 0.34).setFill()
            let gloss = UIBezierPath(ovalIn: CGRect(x: headRect.minX + 4, y: headRect.minY + 3, width: 14, height: 6))
            gloss.fill()
        }

        cache[key] = image
        return image
    }

    static func center(accent: UIColor) -> UIImage {
        let key = "center-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 40, height: 40)) { rect in
            let ctx = UIGraphicsGetCurrentContext()
            UIColor.black.withAlphaComponent(0.22).setFill()
            UIBezierPath(ovalIn: rect.insetBy(dx: 3, dy: 3)).fill()

            fillCircle(rect.insetBy(dx: 5, dy: 5),
                       colors: [UIColor(white: 0.12, alpha: 0.95), UIColor(white: 0.05, alpha: 0.95)],
                       in: ctx)

            drawGradientRing(
                in: rect.insetBy(dx: 6.5, dy: 6.5),
                width: 2.6,
                colors: [accent.adjusted(brightness: 1.2), accent.adjusted(brightness: 0.85)]
            )
            UIColor.white.withAlphaComponent(0.92).setStroke()
            UIBezierPath(ovalIn: rect.insetBy(dx: 13, dy: 13)).stroke(lineWidth: 1.8)

            let crosshairContext = UIGraphicsGetCurrentContext()
            crosshairContext?.setStrokeColor(UIColor.white.withAlphaComponent(0.85).cgColor)
            crosshairContext?.setLineWidth(1.5)
            crosshairContext?.move(to: CGPoint(x: rect.midX, y: 2))
            crosshairContext?.addLine(to: CGPoint(x: rect.midX, y: 8.5))
            crosshairContext?.move(to: CGPoint(x: rect.midX, y: rect.maxY - 2))
            crosshairContext?.addLine(to: CGPoint(x: rect.midX, y: rect.maxY - 8.5))
            crosshairContext?.move(to: CGPoint(x: 2, y: rect.midY))
            crosshairContext?.addLine(to: CGPoint(x: 8.5, y: rect.midY))
            crosshairContext?.move(to: CGPoint(x: rect.maxX - 2, y: rect.midY))
            crosshairContext?.addLine(to: CGPoint(x: rect.maxX - 8.5, y: rect.midY))
            crosshairContext?.strokePath()
        }

        cache[key] = image
        return image
    }

    static func poi(symbol: String, tint: UIColor, accent: UIColor) -> UIImage {
        let key = "poi-\(symbol)-\(tint.cacheKey)-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 34, height: 44)) { rect in
            let ctx = UIGraphicsGetCurrentContext()
            let shell = poiPinPath(in: rect)
            let badge = CGRect(x: 6, y: 4, width: 22, height: 22)

            UIColor.black.withAlphaComponent(0.20).setFill()
            UIBezierPath(ovalIn: CGRect(x: 10, y: 34, width: 14, height: 5)).fill()

            fill(path: shell, with: [UIColor(white: 0.12, alpha: 0.96), UIColor(white: 0.06, alpha: 0.96)], in: ctx)
            UIColor.white.withAlphaComponent(0.30).setStroke()
            shell.stroke(lineWidth: 0.9)

            drawGradientRing(
                in: badge.insetBy(dx: -1.2, dy: -1.2),
                width: 2.4,
                colors: [tint.adjusted(brightness: 1.2), tint.adjusted(brightness: 0.85)]
            )
            fillCircle(badge, colors: [tint.adjusted(brightness: 1.08), tint.adjusted(brightness: 0.92)], in: ctx)
            UIColor.white.withAlphaComponent(0.65).setStroke()
            UIBezierPath(ovalIn: badge).stroke(lineWidth: 0.7)

            let glossRect = CGRect(x: badge.minX + 3, y: badge.minY + 2.5, width: 10, height: 4)
            UIColor.white.withAlphaComponent(0.22).setFill()
            UIBezierPath(ovalIn: glossRect).fill()

            let config = UIImage.SymbolConfiguration(pointSize: 10, weight: .bold)
            let symbolImage = UIImage(systemName: symbol, withConfiguration: config)?
                .withTintColor(.white, renderingMode: .alwaysOriginal)
            symbolImage?.draw(in: CGRect(x: badge.midX - 6, y: badge.midY - 6, width: 12, height: 12))

            if symbol == "fork.knife" {
                accent.withAlphaComponent(0.35).setStroke()
                UIBezierPath(ovalIn: badge.insetBy(dx: -2.8, dy: -2.8)).stroke(lineWidth: 1.1)
            }
        }

        cache[key] = image
        return image
    }

    static func cluster(count: Int, accent: UIColor) -> UIImage {
        let key = "cluster-\(min(count, 99))-\(accent.cacheKey)"
        if let cached = cache[key] { return cached }

        let image = render(size: CGSize(width: 46, height: 46)) { rect in
            let ctx = UIGraphicsGetCurrentContext()
            let core = rect.insetBy(dx: 8, dy: 8)

            UIColor.black.withAlphaComponent(0.18).setFill()
            UIBezierPath(ovalIn: core.offsetBy(dx: 0, dy: 4)).fill()

            UIColor.white.withAlphaComponent(0.07).setFill()
            UIBezierPath(ovalIn: core.insetBy(dx: -4, dy: -4)).fill()

            fillCircle(core, colors: [UIColor(white: 0.13, alpha: 0.96), UIColor(white: 0.05, alpha: 0.98)], in: ctx)
            drawGradientRing(in: core.insetBy(dx: -1, dy: -1), width: 2.2, colors: [accent.withAlphaComponent(0.9), UIColor.white.withAlphaComponent(0.22)])
            UIColor.white.withAlphaComponent(0.12).setStroke()
            UIBezierPath(ovalIn: core).stroke(lineWidth: 0.8)

            let text = count > 99 ? "99+" : "\(count)"
            let attrs: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: count > 9 ? 12 : 13.5, weight: .bold),
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

            UIColor.white.withAlphaComponent(0.18).setFill()
            UIBezierPath(ovalIn: CGRect(x: core.minX + 4, y: core.minY + 3, width: 10, height: 4)).fill()
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

    private static func cityPinPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let cx = rect.midX
        let topY: CGFloat = 4
        let headBottomY: CGFloat = 32
        let bottomY: CGFloat = 45

        path.move(to: CGPoint(x: cx, y: bottomY))
        path.addCurve(to: CGPoint(x: 6, y: 18),
                      controlPoint1: CGPoint(x: cx - 10, y: 36),
                      controlPoint2: CGPoint(x: 7, y: 30))
        path.addArc(withCenter: CGPoint(x: cx, y: 18), radius: 14, startAngle: .pi, endAngle: 0, clockwise: true)
        path.addCurve(to: CGPoint(x: cx, y: bottomY),
                      controlPoint1: CGPoint(x: 33, y: 30),
                      controlPoint2: CGPoint(x: cx + 10, y: 36))
        path.close()
        _ = topY
        _ = headBottomY
        return path
    }

    private static func poiPinPath(in rect: CGRect) -> UIBezierPath {
        let path = UIBezierPath()
        let cx = rect.midX
        path.move(to: CGPoint(x: cx, y: 37))
        path.addCurve(to: CGPoint(x: 5, y: 16),
                      controlPoint1: CGPoint(x: cx - 7.5, y: 30),
                      controlPoint2: CGPoint(x: 5, y: 24))
        path.addArc(withCenter: CGPoint(x: cx, y: 16), radius: 11, startAngle: .pi, endAngle: 0, clockwise: true)
        path.addCurve(to: CGPoint(x: cx, y: 37),
                      controlPoint1: CGPoint(x: 29, y: 24),
                      controlPoint2: CGPoint(x: cx + 7.5, y: 30))
        path.close()
        return path
    }

    private static func fill(path: UIBezierPath, with colors: [UIColor], in context: CGContext?) {
        guard let context else { return }
        context.saveGState()
        path.addClip()
        drawVerticalGradient(in: context, rect: path.bounds.insetBy(dx: -2, dy: -2), colors: colors)
        context.restoreGState()
    }

    private static func fillCircle(_ rect: CGRect, colors: [UIColor], in context: CGContext?) {
        guard let context else { return }
        let path = UIBezierPath(ovalIn: rect)
        context.saveGState()
        path.addClip()
        drawVerticalGradient(in: context, rect: rect, colors: colors)
        context.restoreGState()
    }

    private static func drawGradientRing(in rect: CGRect, width: CGFloat, colors: [UIColor]) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        let ringPath = UIBezierPath(ovalIn: rect)
        let innerPath = UIBezierPath(ovalIn: rect.insetBy(dx: width, dy: width))
        ringPath.append(innerPath.reversing())
        context.saveGState()
        ringPath.addClip()
        drawVerticalGradient(in: context, rect: rect, colors: colors)
        context.restoreGState()
    }

    private static func drawVerticalGradient(in context: CGContext, rect: CGRect, colors: [UIColor]) {
        let cgColors = colors.map(\.cgColor) as CFArray
        guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: cgColors, locations: nil) else { return }
        context.drawLinearGradient(
            gradient,
            start: CGPoint(x: rect.midX, y: rect.minY),
            end: CGPoint(x: rect.midX, y: rect.maxY),
            options: []
        )
    }
}

private extension UIColor {
    var cacheKey: String {
        guard let comps = cgColor.components else { return "0" }
        let vals = comps.map { Int(($0 * 255).rounded()) }
        return vals.map(String.init).joined(separator: "-")
    }

    func adjusted(brightness: CGFloat) -> UIColor {
        var hue: CGFloat = 0
        var sat: CGFloat = 0
        var bri: CGFloat = 0
        var alpha: CGFloat = 0
        if getHue(&hue, saturation: &sat, brightness: &bri, alpha: &alpha) {
            return UIColor(hue: hue, saturation: sat, brightness: max(0, min(1, bri * brightness)), alpha: alpha)
        }
        var white: CGFloat = 0
        if getWhite(&white, alpha: &alpha) {
            return UIColor(white: max(0, min(1, white * brightness)), alpha: alpha)
        }
        return self
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
