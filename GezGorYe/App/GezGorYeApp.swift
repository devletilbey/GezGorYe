import SwiftUI

@main
struct GezGorYeApp: App {
    var body: some Scene {
        WindowGroup {
            RootMapView()
                .preferredColorScheme(.dark)
        }
    }
}
