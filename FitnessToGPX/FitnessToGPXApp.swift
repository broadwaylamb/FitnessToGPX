import SwiftUI

@main
struct FitnessToGPXApp: App {
    var body: some Scene {
        WindowGroup {
            WorkoutListView()
        }
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "<bundle identifier>"
    }
}
