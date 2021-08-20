import SwiftUI

@main
struct FitnessToGPXApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }

    static var bundleIdentifier: String {
        Bundle.main.bundleIdentifier ?? "<bundle identifier>"
    }
}
