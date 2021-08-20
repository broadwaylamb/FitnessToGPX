import HealthKit
import CoreLocation
import os

private let supportedActivities: [HKWorkoutActivityType] = [
    .cycling,
    .running,
    .walking,
    .hiking,
    .swimming,
    .crossCountrySkiing,
    .downhillSkiing,
    .snowboarding,
    .skatingSports,
]

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .cycling: return "Cycle"
        case .running: return "Run"
        case .walking: return "Walk"
        case .hiking: return "Hike"
        case .swimming: return "Swim"
        case .crossCountrySkiing: return "Cross-country Skiing"
        case .downhillSkiing: return "Downhill Skiing"
        case .snowboarding: return "Snowboarding"
        case .skatingSports: return "Skating"
        default: return "Workout"
        }
    }
}

extension HKHealthStore {
    /// A general query that returns a snapshot of all the matching samples currently
    /// saved in the HealthKit store.
    /// - Parameters:
    ///   - sampleType: The type of sample to search for. This object can be an instance
    ///     of the `HKCategoryType`, `HKCorrelationType`, `HKQuantityType`,
    ///     or `HKWorkoutType` class.
    ///   - predicate: A predicate that limits the results returned by the query.
    ///     Pass `nil` to receive all the samples of the specified type.
    ///   - limit: The maximum number of samples returned by the query. If you want to
    ///     return all matching samples, use `HKObjectQueryNoLimit`.
    ///   - sortDescriptors: An array of sort descriptors that specify the order of
    ///     the results returned by this query. Pass `nil` if you don’t need the results
    ///     in a specific order.
    /// - Returns: An array containing the samples found by the query.
    func query(sampleType: HKSampleType,
               predicate: NSPredicate?,
               limit: Int,
               sortDescriptors: [NSSortDescriptor]?) async throws -> [HKSample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sampleType,
                predicate: predicate,
                limit: limit,
                sortDescriptors: sortDescriptors,
                resultsHandler: { query, samples, error in
                    if let samples = samples {
                        continuation.resume(returning: samples)
                    } else if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        fatalError("HealthKit contract violation")
                    }
                }
            )

            execute(query)
        }
    }

    /// Use a workout route query to access the location data associated with
    /// an `HKWorkoutRoute`. Because a route sample can include a large number of
    /// `CLLocation` objects, the query asynchronously returns the locations in batches.
    /// For detailed instructions, see Reading Route Data.
    ///
    /// - Parameter route: The workout route containing the location data.
    /// - Returns: Batches of location data as an asynchronous stream.
    func workoutRouteQuery(
        route: HKWorkoutRoute
    ) -> AsyncThrowingStream<[CLLocation], Error> {
        AsyncThrowingStream { continuation in
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                if let error = error {
                    continuation.finish(throwing: error)
                    return
                } else if let locations = locations {
                    continuation.yield(locations)
                } else {
                    fatalError("HealthKit contract violation")
                }
                if done {
                    continuation.finish(throwing: nil)
                }
            }

            continuation.onTermination = { @Sendable _ in
                self.stop(query)
            }

            execute(query)
        }
    }
}

struct HealthKitHelper {

    let logger = Logger(subsystem: FitnessToGPXApp.bundleIdentifier,
                        category: "HealthKitHelper")

    private var store = HKHealthStore()

    func requestAuthorization() async throws {
        logger.debug("Requesting HealthKit authorization")
        guard HKHealthStore.isHealthDataAvailable() else {
            logger.info("HealthKit is not available")
            fatalError("TODO")
        }

        try await store.requestAuthorization(
            toShare: [],
            read: [HKWorkoutType.workoutType(),
                   HKSeriesType.workoutRoute(),
                   HKQuantityType.quantityType(forIdentifier: .heartRate)!]
        )
    }

    /// Returns an array of workouts of supported activity types sorted from the most
    /// recent to the oldest.
    func loadWorkouts() async throws -> [HKWorkout] {
        logger.debug("Loading workouts from HealthKit")
        return try await store.query(
            sampleType: HKWorkoutType.workoutType(),
            predicate: NSCompoundPredicate(
                orPredicateWithSubpredicates:
                    supportedActivities.map(HKQuery.predicateForWorkouts)
            ),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [
                NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            ]
        ) as! [HKWorkout]
    }

    func route(
        for workout: HKWorkout
    ) async throws -> LazyMapSequence<[HKWorkoutRoute], AsyncThrowingStream<[CLLocation], Error>> {
        logger.debug("Loading route for workout \(workout)")
        let workoutSamples = try await store
            .query(sampleType: HKSeriesType.workoutRoute(),
                   predicate: HKQuery.predicateForObjects(from: workout),
                   limit: HKObjectQueryNoLimit,
                   sortDescriptors: [
                    NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                     ascending: true)
                   ]
            ) as! [HKWorkoutRoute]
        return workoutSamples.lazy.map(store.workoutRouteQuery(route:))
    }


    func heartRate(for workout: HKWorkout) async throws -> [HKQuantitySample] {
        logger.debug("Loading heart rate data for workout \(workout)")
        return try await store.query(
            sampleType: HKObjectType.quantityType(forIdentifier: .heartRate)!,
            predicate: HKQuery.predicateForSamples(withStart: workout.startDate,
                                                   end: workout.endDate,
                                                   options: .strictStartDate),
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [
                NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
            ]
        ) as! [HKQuantitySample]
    }
}
