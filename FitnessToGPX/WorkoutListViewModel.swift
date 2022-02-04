import SwiftUI
import HealthKit

@MainActor
final class WorkoutListViewModel: ObservableObject {

    @Published var workouts: [HKWorkout] = []
}
