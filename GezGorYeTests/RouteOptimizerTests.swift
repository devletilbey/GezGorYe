import XCTest
@testable import GezGorYe

final class RouteOptimizerTests: XCTestCase {
    func testBuildFastestPlanOrdersByNearestNeighbor() {
        let optimizer = RouteOptimizer(averageSpeedKmH: 40)
        let start = GeoCoordinate(latitude: 40.0000, longitude: 31.0000)

        let poiNear = POI(
            name: "Near",
            category: .nature,
            coordinate: GeoCoordinate(latitude: 40.0010, longitude: 31.0010),
            shortDescription: "",
            recommendedVisitMinutes: 10
        )

        let poiFar = POI(
            name: "Far",
            category: .nature,
            coordinate: GeoCoordinate(latitude: 40.5000, longitude: 31.5000),
            shortDescription: "",
            recommendedVisitMinutes: 10
        )

        let plan = optimizer.buildFastestPlan(start: start, pois: [poiFar, poiNear])

        XCTAssertEqual(plan.orderedStops.first?.poi.name, "Near")
        XCTAssertEqual(plan.orderedStops.count, 2)
        XCTAssertGreaterThan(plan.totalMinutes, 0)
    }
}
