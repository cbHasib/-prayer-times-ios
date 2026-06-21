import XCTest
@testable import PrayerKit

/// Calibration harness (not a gate). Reads the raw Diyanet CSVs from the repo
/// `data/diyanet/` directory, runs the engine for candidate coordinates, and
/// prints the per-prayer error distribution so coordinates/elevation can be
/// tuned to the ±1-minute requirement. Disabled-by-naming: invoke explicitly
/// with `swift test --filter DiyanetCalibration`.
final class DiyanetCalibration: XCTestCase {

    private struct City {
        let csv: String
        let coords: Coordinates
    }

    // Candidate district reference coordinates (to be refined from the report).
    private let cities: [City] = [
        City(csv: "prayer-times-ankara-ankara.csv",
             coords: Coordinates(latitude: 39.9272, longitude: 32.8644, elevation: 938)),
        City(csv: "prayer-times-istanbul-basaksehir.csv",
             coords: Coordinates(latitude: 41.0931, longitude: 28.8021, elevation: 100)),
        City(csv: "prayer-times-istanbul-arnavutkoy.csv",
             coords: Coordinates(latitude: 41.1843, longitude: 28.7339, elevation: 120))
    ]

    func testReportDeltas() throws {
        try XCTSkipUnless(dataDirExists(), "Repo data/diyanet not present; calibration is a dev-only tool.")
        let tz = TZ.make("Europe/Istanbul")
        let order: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]

        for city in cities {
            let rows = try readCSV(city.csv)
            var deltas: [Prayer: [Int]] = [:]
            for row in rows {
                let p = DiyanetAdapter().resolve(for: city.coords)
                let times = PrayerTimeEngine.calculate(
                    date: row.date, coordinates: city.coords, params: p, timeZone: tz
                )
                for prayer in order {
                    guard let t = times[prayer], let exp = row.times[prayer] else { continue }
                    deltas[prayer, default: []].append(t.minutesOfDay(in: tz) - exp)
                }
            }
            print("\n=== \(city.csv) @ \(city.coords.latitude),\(city.coords.longitude) elev \(city.coords.elevation) ===")
            for prayer in order {
                let ds = deltas[prayer] ?? []
                let absMax = ds.map { abs($0) }.max() ?? 0
                let mean = ds.isEmpty ? 0 : Double(ds.reduce(0, +)) / Double(ds.count)
                print(String(format: "%-8@ min=%+3d max=%+3d |max|=%d meanΔ=%+.2f",
                             prayer.rawValue as NSString,
                             ds.min() ?? 0, ds.max() ?? 0, absMax, mean))
            }
        }
    }

    /// Sweep Başakşehir latitude to locate the value that brings every prayer
    /// (Fajr in particular) within ±1 minute.
    func testSweepBasaksehirLatitude() throws {
        try XCTSkipUnless(dataDirExists(), "Repo data/diyanet not present; calibration is a dev-only tool.")
        let tz = TZ.make("Europe/Istanbul")
        let rows = try readCSV("prayer-times-istanbul-basaksehir.csv")
        let order: [Prayer] = [.fajr, .sunrise, .dhuhr, .asr, .maghrib, .isha]
        print("\n=== Başakşehir latitude sweep (lon 28.8021) ===")
        for latTimes100 in stride(from: 4104, through: 4112, by: 1) {
            let lat = Double(latTimes100) / 100
            let coords = Coordinates(latitude: lat, longitude: 28.8021)
            var worst = 0, worstFajr = 0
            for row in rows {
                let times = PrayerTimeEngine.calculate(
                    date: row.date, coordinates: coords,
                    params: DiyanetAdapter().resolve(for: coords), timeZone: tz)
                for p in order {
                    guard let t = times[p], let e = row.times[p] else { continue }
                    let d = abs(t.minutesOfDay(in: tz) - e)
                    worst = max(worst, d)
                    if p == .fajr { worstFajr = max(worstFajr, d) }
                }
            }
            print(String(format: "lat %.2f : worstFajr=%d worstAny=%d", lat, worstFajr, worst))
        }
    }

    // MARK: - CSV reading

    private struct Row {
        let date: DateComponents
        let times: [Prayer: Int]   // minutes since midnight
    }

    private func dataDir() -> URL {
        // .../PrayerKit/Tests/PrayerKitTests/DiyanetCalibration.swift → repo root.
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()   // PrayerKitTests
            .deletingLastPathComponent()   // Tests
            .deletingLastPathComponent()   // PrayerKit
            .deletingLastPathComponent()   // repo root
            .appendingPathComponent("data/diyanet", isDirectory: true)
    }

    private func dataDirExists() -> Bool {
        FileManager.default.fileExists(atPath: dataDir().path)
    }

    private func readCSV(_ name: String) throws -> [Row] {
        let url = dataDir().appendingPathComponent(name)
        let text = try String(contentsOf: url, encoding: .utf8)
            .replacingOccurrences(of: "\r", with: "")
        var rows: [Row] = []
        for line in text.split(separator: "\n").dropFirst() {
            let cols = line.split(separator: ",", omittingEmptySubsequences: false).map {
                $0.trimmingCharacters(in: .whitespaces)
            }
            guard cols.count >= 8 else { continue }
            let d = cols[0].split(separator: ".").compactMap { Int($0) }
            guard d.count == 3 else { continue }
            let date = DateComponents(year: d[2], month: d[1], day: d[0])
            func mins(_ s: String) -> Int {
                let hm = s.split(separator: ":").compactMap { Int($0) }
                return hm.count == 2 ? hm[0] * 60 + hm[1] : -1
            }
            let times: [Prayer: Int] = [
                .fajr: mins(cols[2]), .sunrise: mins(cols[3]), .dhuhr: mins(cols[4]),
                .asr: mins(cols[5]), .maghrib: mins(cols[6]), .isha: mins(cols[7])
            ]
            rows.append(Row(date: date, times: times))
        }
        return rows
    }
}
