import CoreLocation

struct RouteStop: Hashable {
    let poi: POI
    let distanceFromPreviousKm: Double
    let travelMinutes: Int
    let visitMinutes: Int
}

struct RoutePlan: Hashable {
    let orderedStops: [RouteStop]
    let totalDistanceKm: Double
    let totalMinutes: Int
}

protocol RouteOptimizing {
    func buildFastestPlan(start: GeoCoordinate, pois: [POI]) -> RoutePlan
}

struct RouteOptimizer: RouteOptimizing {
    private let averageSpeedKmH: Double

    init(averageSpeedKmH: Double = 38) {
        self.averageSpeedKmH = averageSpeedKmH
    }

    func buildFastestPlan(start: GeoCoordinate, pois: [POI]) -> RoutePlan {
        guard !pois.isEmpty else {
            return RoutePlan(orderedStops: [], totalDistanceKm: 0, totalMinutes: 0)
        }

        let initialOrder = buildNearestNeighborOrder(start: start.location, pois: pois)
        let optimizedOrder = improveRouteWithTwoOpt(start: start.location, route: initialOrder)

        var current = start.location
        var totalDistance: Double = 0
        var totalMinutes = 0
        var stops: [RouteStop] = []

        for poi in optimizedOrder {
            let distance = distanceKm(from: current, to: poi.coordinate.location)
            let travelMinutes = Int(ceil((distance / averageSpeedKmH) * 60))
            let visitMinutes = poi.recommendedVisitMinutes

            totalDistance += distance
            totalMinutes += travelMinutes + visitMinutes

            stops.append(
                RouteStop(
                    poi: poi,
                    distanceFromPreviousKm: distance,
                    travelMinutes: travelMinutes,
                    visitMinutes: visitMinutes
                )
            )

            current = poi.coordinate.location
        }

        return RoutePlan(
            orderedStops: stops,
            totalDistanceKm: totalDistance,
            totalMinutes: totalMinutes
        )
    }

    private func buildNearestNeighborOrder(start: CLLocationCoordinate2D, pois: [POI]) -> [POI] {
        var remaining = pois
        var current = start
        var ordered: [POI] = []

        while !remaining.isEmpty {
            let nextIndex = indexOfNearest(from: current, candidates: remaining)
            let next = remaining.remove(at: nextIndex)
            ordered.append(next)
            current = next.coordinate.location
        }

        return ordered
    }

    private func improveRouteWithTwoOpt(start: CLLocationCoordinate2D, route: [POI]) -> [POI] {
        guard route.count > 2 else { return route }

        var best = route
        var bestDistance = routeDistance(start: start, orderedPOIs: best)
        var improved = true
        var iterations = 0

        while improved && iterations < 24 {
            improved = false
            iterations += 1

            for i in 0..<(best.count - 1) {
                for k in (i + 1)..<best.count {
                    let candidate = twoOptSwap(route: best, from: i, to: k)
                    let candidateDistance = routeDistance(start: start, orderedPOIs: candidate)

                    if candidateDistance + 0.001 < bestDistance {
                        best = candidate
                        bestDistance = candidateDistance
                        improved = true
                    }
                }
            }
        }

        return best
    }

    private func twoOptSwap(route: [POI], from i: Int, to k: Int) -> [POI] {
        let prefix = Array(route[..<i])
        let reversed = Array(route[i...k].reversed())
        let suffix = Array(route[(k + 1)...])
        return prefix + reversed + suffix
    }

    private func routeDistance(start: CLLocationCoordinate2D, orderedPOIs: [POI]) -> Double {
        var total: Double = 0
        var current = start

        for poi in orderedPOIs {
            total += distanceKm(from: current, to: poi.coordinate.location)
            current = poi.coordinate.location
        }

        return total
    }

    private func indexOfNearest(from source: CLLocationCoordinate2D, candidates: [POI]) -> Int {
        var nearestIndex = 0
        var nearestDistance = Double.greatestFiniteMagnitude

        for (index, poi) in candidates.enumerated() {
            let distance = distanceKm(from: source, to: poi.coordinate.location)
            if distance < nearestDistance {
                nearestDistance = distance
                nearestIndex = index
            }
        }

        return nearestIndex
    }

    private func distanceKm(from first: CLLocationCoordinate2D, to second: CLLocationCoordinate2D) -> Double {
        let firstLocation = CLLocation(latitude: first.latitude, longitude: first.longitude)
        let secondLocation = CLLocation(latitude: second.latitude, longitude: second.longitude)
        return firstLocation.distance(from: secondLocation) / 1000
    }
}
