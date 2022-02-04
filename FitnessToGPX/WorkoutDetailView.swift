import SwiftUI
import HealthKit
import MapKit

private let titleDateFormatter = with(DateFormatter()) {
    $0.dateStyle = .medium
    $0.timeStyle = .none
}

private let timeIntervalFormatter = with(DateIntervalFormatter()) {
    $0.dateStyle = .none
    $0.timeStyle = .short
}

private let distanceFormatter = LengthFormatter()

struct WorkoutDetailView: View {

    let workout: HKWorkout

    let logger = Logger(category: "WorkoutDetailView")

    @ObservedObject private var gpxExportState = GPXExportState()

    var body: some View {
        VStack {
            HStack {
                VStack(alignment: .leading) {
                    Text(workout.workoutActivityType.name)
                        .font(.title)
                    Text(timeIntervalFormatter.string(from: workout.startDate,
                                                      to: workout.endDate))
                    if let distance = workout.totalDistance {
                        Text(distanceFormatter.string(fromValue: distance.doubleValue(for: .meterUnit(with: .kilo)),
                                                      unit: .kilometer))
                            .font(.system(.title, design: .rounded))
                    }
                }
                Spacer()
            }
            .padding()
            Spacer()
            Group {
                if gpxExportState.isExportInProgress {
                    ProgressView()
                } else {
                    Button("Export to GPX") {
                        gpxExportState.exportWorkouts(CollectionOfOne(workout))
                    }
                }
            }
            .padding()
        }
        .navigationTitle(titleDateFormatter.string(from: workout.startDate))
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            gpxExportState.cancelExport()
        }
        .exportGPX($gpxExportState)
    }
}

struct WorkoutView_Previews: PreviewProvider {

    static let workouts = [
        HKWorkout(activityType: .cycling,
                  start: DateComponents(calendar: .current,
                                        year: 2021,
                                        month: 6,
                                        day: 12,
                                        hour: 13,
                                        minute: 15).date!,
                  end: DateComponents(calendar: .current,
                                      year: 2021,
                                      month: 6,
                                      day: 12,
                                      hour: 14,
                                      minute: 53).date!,
                  duration: 0,
                  totalEnergyBurned: nil,
                  totalDistance: HKQuantity(unit: .meterUnit(with: .kilo),
                                            doubleValue: 18.45),
                  metadata: nil),
        HKWorkout(activityType: .running,
                  start: DateComponents(calendar: .current,
                                        year: 2021,
                                        month: 6,
                                        day: 12,
                                        hour: 23,
                                        minute: 50).date!,
                  end: DateComponents(calendar: .current,
                                      year: 2021,
                                      month: 6,
                                      day: 13,
                                      hour: 0,
                                      minute: 30).date!,
                  duration: 0,
                  totalEnergyBurned: nil,
                  totalDistance: HKQuantity(unit: .meterUnit(with: .kilo),
                                            doubleValue: 7.01),
                  metadata: nil)
    ]

    static var previews: some View {
        Group {
            ForEach(workouts, id: \.self) { workout in
                NavigationView {
                    WorkoutDetailView(workout: workout)
                }
            }
        }
    }
}
