import SwiftUI
import HealthKit

private let distanceFormatter = LengthFormatter()

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .short
    return formatter
}()

struct ContentView: View {

    @State var workouts: [HKWorkout] = []

    let helper = HealthKitHelper()

    var body: some View {
        List(workouts, id: \.uuid) { workout in
            VStack {
                Text(workout.workoutActivityType.name)
                HStack {
                    if let distance = workout.totalDistance {
                        Text(distanceFormatter.unitString(fromValue: distance.doubleValue(for: .meterUnit(with: .kilo)),
                                                          unit: .kilometer))
                    }
                    Spacer()
                    Text(dateFormatter.string(from: workout.startDate))
                }
            }
        }.task {
            do {
                workouts = try await helper.loadWorkouts()
            } catch {
                fatalError("TODO")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            workouts: [
                HKWorkout(activityType: .cycling,
                          start: try! Date("09.06.2018 13:15", strategy: .dateTime),
                          end: try! Date("09.06.2018 14:53", strategy: .dateTime),
                          duration: 0,
                          totalEnergyBurned: nil,
                          totalDistance: HKQuantity(unit: .meterUnit(with: .kilo),
                                                    doubleValue: 18.45),
                          metadata: nil)
            ]
        )
    }
}
