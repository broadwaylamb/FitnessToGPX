import SwiftUI
import HealthKit

@MainActor
final class GPXExportState: ObservableObject {

    private let logger = Logger(category: "GPXExportState")

    let helper = HealthKitHelper()

    fileprivate var files: [TemporaryGPXFile] = []

    @Published fileprivate var exportSheetDisplayed = false

    private var exportGPXTask: Task<Void, Never>?

    @Published private(set) var progress: Progress?

    var isExportInProgress: Bool { progress != nil }

    private func exportWorkoutsAsync<Workouts: Collection>(
        _ workouts: Workouts
    ) async throws -> [TemporaryGPXFile]
        where Workouts.Element == HKWorkout
    {
        try await withThrowingTaskGroup(of: TemporaryGPXFile.self) { group in
            for workout in workouts {
                group.addTask {
                    let file = try await self.helper.exportGPX(for: workout)
                    return file
                }
            }

            var files = [TemporaryGPXFile]()
            files.reserveCapacity(workouts.count)

            for try await file in group {
                files.append(file)
                self.progress?.completedUnitCount += 1
            }

            return files
        }
    }

    func exportWorkouts<Workouts: Collection>(_ workouts: Workouts)
        where Workouts.Element == HKWorkout
    {
        logger.debug("Exporting workouts")
        exportGPXTask = Task {
            progress = Progress(totalUnitCount: Int64(workouts.count))
            do {
                self.files = try await self.exportWorkoutsAsync(workouts)
                exportSheetDisplayed = true
                logger.debug("Export complete")
            } catch is CancellationError {
                logger.debug("Export cancelled")
            } catch {
                // TODO
                logger.info("\(error.localizedDescription)")
            }

            progress = nil
            exportGPXTask = nil
        }
    }

    func cancelExport() {
        exportGPXTask?.cancel()
        exportGPXTask = nil
    }
}

extension View {
    func exportGPX(_ binding: ObservedObject<GPXExportState>.Wrapper) -> some View {
        sheet(isPresented: binding.exportSheetDisplayed) {
            ShareSheet(activityItems: binding.files.wrappedValue.map(\.url))
        }
    }
}
