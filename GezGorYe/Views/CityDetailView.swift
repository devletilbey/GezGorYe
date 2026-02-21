import SwiftUI

struct CityDetailView: View {
    let city: City

    @EnvironmentObject private var viewModel: TravelGuideViewModel
    @EnvironmentObject private var settings: AppSettings

    var body: some View {
        VStack(spacing: 14) {
            categoryFilter
            tripIntelligence
            highlightsSection
            routeTimeline
            foodsSection
            notesSection
        }
    }

    private var categoryFilter: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(POICategory.allCases) { category in
                    let selected = viewModel.selectedCategories.contains(category)
                    Button {
                        viewModel.toggleCategory(category)
                    } label: {
                        Label(category.title, systemImage: category.symbol)
                            .font(.caption.weight(.semibold))
                            .padding(.horizontal, 11)
                            .padding(.vertical, 8)
                            .background(
                                selected
                                    ? settings.theme.palette.accent.opacity(0.26)
                                    : .white.opacity(0.1),
                                in: Capsule()
                            )
                            .overlay(
                                Capsule().stroke(.white.opacity(selected ? 0.5 : 0.2), lineWidth: 1)
                            )
                    }
                    .foregroundStyle(.white)
                }
            }
            .padding(.horizontal, 2)
        }
    }

    private var tripIntelligence: some View {
        let plan = viewModel.routePlan

        return premiumCard(
            title: "Trip Intelligence",
            subtitle: "Apple seviyesinde zaman-optimizasyon paneli"
        ) {
            HStack(spacing: 8) {
                statChip(value: "\(plan.orderedStops.count)", label: "Durak")
                statChip(value: "\(Int(plan.totalDistanceKm.rounded())) km", label: "Mesafe")
                statChip(value: formatMinutes(plan.totalMinutes), label: "Toplam Süre")
            }
        }
    }

    private var highlightsSection: some View {
        premiumCard(
            title: "Öne Çıkan Noktalar",
            subtitle: "Şehirde ilk görülmesi gereken lokasyonlar"
        ) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(viewModel.filteredPOIs) { poi in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Image(systemName: poi.category.symbol)
                                Text(poi.category.title)
                            }
                            .font(.caption2.weight(.bold))
                            .foregroundStyle(settings.theme.palette.secondaryAccent)

                            Text(poi.name)
                                .font(.subheadline.weight(.bold))
                                .foregroundStyle(.white)

                            Text(poi.shortDescription)
                                .font(.caption)
                                .lineLimit(2)
                                .foregroundStyle(.white.opacity(0.8))

                            Spacer()

                            Text("\(poi.recommendedVisitMinutes) dk")
                                .font(.caption2.weight(.bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 5)
                                .background(.white.opacity(0.16), in: Capsule())
                        }
                        .frame(width: 182, height: 138)
                        .padding(10)
                        .background(settings.theme.palette.cardOverlay, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
        }
    }

    private var routeTimeline: some View {
        let plan = viewModel.routePlan

        return premiumCard(
            title: "En Verimli Rota",
            subtitle: "Yakın komşu + 2-opt iyileştirme"
        ) {
            VStack(spacing: 8) {
                ForEach(Array(plan.orderedStops.enumerated()), id: \.element.poi.id) { index, stop in
                    HStack(alignment: .top, spacing: 10) {
                        VStack(spacing: 0) {
                            Circle()
                                .fill(settings.theme.palette.accent)
                                .frame(width: 8, height: 8)
                            Rectangle()
                                .fill(.white.opacity(index == plan.orderedStops.count - 1 ? 0 : 0.26))
                                .frame(width: 2, height: index == plan.orderedStops.count - 1 ? 0 : 30)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(index + 1). \(stop.poi.name)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.white)

                            Text("Sürüş: \(stop.travelMinutes) dk  •  Gezi: \(stop.visitMinutes) dk  •  \(String(format: "%.1f", stop.distanceFromPreviousKm)) km")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }

                        Spacer()
                    }
                }
            }
        }
    }

    private var foodsSection: some View {
        premiumCard(
            title: "Yöresel Lezzetler",
            subtitle: "\(city.name) mutfağından seçilmiş tatlar"
        ) {
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100), spacing: 8)], alignment: .leading, spacing: 8) {
                ForEach(city.localFoods, id: \.self) { food in
                    Text(food)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(.white.opacity(0.14), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
            }
        }
    }

    private var notesSection: some View {
        premiumCard(
            title: "Akıllı Seyahat Notları",
            subtitle: "Kısa, net ve uygulanabilir öneriler"
        ) {
            VStack(alignment: .leading, spacing: 8) {
                ForEach(city.notes, id: \.self) { note in
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundStyle(settings.theme.palette.secondaryAccent)
                        Text(note)
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.9))
                    }
                }
            }
        }
    }

    private func premiumCard<Content: View>(title: String, subtitle: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline.weight(.bold))
                .foregroundStyle(.white)

            Text(subtitle)
                .font(.caption)
                .foregroundStyle(.white.opacity(0.8))

            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(settings.theme.palette.cardOverlay, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(.white.opacity(0.16), lineWidth: 1)
        )
    }

    private func statChip(value: String, label: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.caption.weight(.bold))
                .foregroundStyle(.white)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.white.opacity(0.75))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 9)
        .background(.white.opacity(0.13), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func formatMinutes(_ total: Int) -> String {
        let hours = total / 60
        let mins = total % 60
        if hours == 0 { return "\(mins) dk" }
        return "\(hours)s \(mins)dk"
    }
}
