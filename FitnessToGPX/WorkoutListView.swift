import SwiftUI
import HealthKit

private let distanceFormatter = LengthFormatter()

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.timeStyle = .none
    formatter.dateStyle = .short
    return formatter
}()

struct WorkoutListView: View {

    @State var workouts: [HKWorkout] = []

    @State private var selectedWorkouts = Set<HKWorkout>()

    @State private var editMode = EditMode.inactive

    @ObservedObject private var gpxExportState = GPXExportState()

    let helper = HealthKitHelper()

    var body: some View {
        NavigationView {
            ZStack {
                List(workouts,
                     id: \.self,
                     selection: $selectedWorkouts,
                     rowContent: WorkoutListCell.init)
                .listStyle(.inset)
                .refreshable(action: refresh)
                .navigationTitle("Workouts")
                .task(refresh)
                .toolbar {
                    ToolbarItemGroup(placement: ToolbarItemPlacement.navigationBarTrailing) {
                        if editMode.isEditing {
                            Button("Export selected") {
                                gpxExportState.exportWorkouts(selectedWorkouts)
                            }
                            .disabled(selectedWorkouts.isEmpty)
                        }
                        Button(editMode.isEditing ? "Done" : "Select") {
                            editMode = editMode.isEditing ? .inactive : .active
                        }
                    }
                }
                .animation(.default, value: editMode)
                .onChange(of: editMode.isEditing) { isEditing in
                    if !isEditing {
                        selectedWorkouts.removeAll()
                    }
                }
                .environment(\.editMode, $editMode)
                if let progress = gpxExportState.progress {
                    VStack {
                        ProgressBar(progress: progress)
                        Spacer()
                    }
                }
            }
            .exportGPX($gpxExportState)
        }
    }

    @Sendable func refresh() async {
        guard workouts.isEmpty else { return }
        do {
            try await helper.requestAuthorization()
            workouts = try await helper.loadWorkouts()
        } catch {
            // TODO
        }
    }
}

struct WorkoutListCell: View {

    let workout: HKWorkout

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(workout.workoutActivityType.name)
            NavigationLink {
                WorkoutDetailView(workout: workout)
            } label: {
                HStack(alignment: .firstTextBaseline) {
                    if let distance = workout.totalDistance {
                        Text(distanceFormatter.string(fromValue: distance.doubleValue(for: .meterUnit(with: .kilo)),
                                                      unit: .kilometer))
                            .font(.system(.title, design: .rounded))
                    }
                    Spacer()
                    Text(dateFormatter.string(from: workout.startDate))
                }
            }
        }
    }
}

struct ProgressBar: View {

    let progress: Progress

    var body: some View {
        ProgressView(progress)
            .padding()
            .translucentBackground(style: .systemMaterial)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WorkoutListView(
                workouts: [
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
                                                    day: 13,
                                                    hour: 9,
                                                    minute: 00).date!,
                              end: DateComponents(calendar: .current,
                                                  year: 2021,
                                                  month: 6,
                                                  day: 13,
                                                  hour: 10,
                                                  minute: 00).date!,
                              duration: 0,
                              totalEnergyBurned: nil,
                              totalDistance: HKQuantity(unit: .meterUnit(with: .kilo),
                                                        doubleValue: 18.45),
                              metadata: nil),
                    HKWorkout(activityType: .crossCountrySkiing,
                              start: DateComponents(calendar: .current,
                                                    year: 2021,
                                                    month: 2,
                                                    day: 2,
                                                    hour: 14,
                                                    minute: 23).date!,
                              end: DateComponents(calendar: .current,
                                                  year: 2021,
                                                  month: 2,
                                                  day: 2,
                                                  hour: 15,
                                                  minute: 00).date!,
                              duration: 0,
                              totalEnergyBurned: nil,
                              totalDistance: nil,
                              metadata: nil),
                ]
            )
            ProgressBar(
                progress: with(Progress(totalUnitCount: 3)) { $0.completedUnitCount = 2 }
            ).previewLayout(.sizeThatFits)
        }
    }
}
