import HealthKit
import os
import CoreLocation
import Foundation

final class TemporaryGPXFile {
    let url: URL

    init(name: String) {
        self.url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            .appendingPathComponent(name, isDirectory: false)
            .appendingPathExtension("gpx")
    }

    deinit {
        try? FileManager.default.removeItem(at: url)
    }
}

actor GPXExporter {

    private static let isoDateFormatter = ISO8601DateFormatter()

    private static let trackNameDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .medium
        return formatter
    }()

    private static let fileNameDateFormatter: DateFormatter = {
        let formatter = DateFormatter();
        formatter.dateFormat = "yyyy-MM-dd_hh.mm.ss"
        return formatter;
    }()

    private static let bpmUnit = HKUnit.count().unitDivided(by: .minute())

    let logger = Logger(subsystem: FitnessToGPXApp.bundleIdentifier,
                        category: "GPXExporter")

    func save<Segments: Sequence>(
        workout: HKWorkout,
        routeSegments: Segments,
        heartRate: [HKQuantitySample]
    ) async throws -> TemporaryGPXFile
        where Segments.Element: AsyncSequence,
              Segments.Element.Element == [CLLocation]
    {
        let temporaryGPXFile = TemporaryGPXFile(name: """
\(Self.fileNameDateFormatter.string(from: workout.startDate))_\
\(workout.workoutActivityType.name)
""")

        logger.debug("Saving workout data to \(temporaryGPXFile.url)")

        let destinationFile = try FileHandle(forWritingTo: temporaryGPXFile.url)

        logger.debug("Writing GPX data")

        try destinationFile
            .writeUTF8("""
<?xml version="1.0" encoding="UTF-8"?>\
<gpx creator="AppleFitnessToGPX" \
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" \
xsi:schemaLocation="http://www.topografix.com/GPX/1/1 \
http://www.topografix.com/GPX/1/1/gpx.xsd \
http://www.garmin.com/xmlschemas/GpxExtensions/v3 \
http://www.garmin.com/xmlschemas/GpxExtensionsv3.xsd \
http://www.garmin.com/xmlschemas/TrackPointExtension/v1 \
http://www.garmin.com/xmlschemas/TrackPointExtensionv1.xsd" \
version="1.1" \
xmlns="http://www.topografix.com/GPX/1/1" \
xmlns:gpxtpx="http://www.garmin.com/xmlschemas/TrackPointExtension/v1" \
xmlns:gpxx="http://www.garmin.com/xmlschemas/GpxExtensions/v3">\
<metadata>\
<time>\(Self.isoDateFormatter.string(from: workout.startDate))</time>\
</metadata>\
<trk><name>\(Self.trackNameDateFormatter.string(from: workout.startDate)) \
\(workout.workoutActivityType.name)</name>
""")

        var remainingHeartRateSamples = heartRate[...]
        var lastHeartRateValue: Double?

        for segment in routeSegments {
            try destinationFile.writeUTF8("<trkseg>")
            for try await batch in segment {
                var buffer = ""
                for location in batch {
                    buffer += """
<trkpt lat="\(location.coordinate.latitude)" lon="\(location.coordinate.longitude)">\
<ele>\(location.altitude)</ele>\
<time>\(Self.isoDateFormatter.string(from: location.timestamp))</time>
"""
                    // Search for the latest heart rate sample that took place before
                    // this location was recorded.
                    while let sample = remainingHeartRateSamples.first,
                          sample.startDate < location.timestamp {
                        lastHeartRateValue = sample
                            .quantity
                            .doubleValue(for: Self.bpmUnit)
                        remainingHeartRateSamples = remainingHeartRateSamples[1...]
                    }

                    if let lastHeartRateValue = lastHeartRateValue {
                        buffer += """
<extensions>\
<gpxtpx:TrackPointExtension>\
<gpxtpx:hr>\(lastHeartRateValue)</gpxtpx:hr>\
</gpxtpx:TrackPointExtension>\
</extensions>
"""
                    }

                    buffer += "</trkpt>"
                }
                try destinationFile.writeUTF8(buffer)
            }
            try destinationFile.writeUTF8("</trkseg>")
        }

        try destinationFile.writeUTF8("</trk></gpx>")

        logger.debug("Successfully written GPX data")

        return temporaryGPXFile
    }
}

extension FileHandle {
    func writeUTF8(_ string: String) throws {
        try write(contentsOf: Data(string.utf8))
    }
}
