import WidgetKit
import SwiftUI
import PrayerKit

struct AppGroupSettingsLoader {
    static let suiteName = "group.co.hasib.prayertimes"
    static let key = "appSettings.v1"
    static let defaultCoordinates = Coordinates(latitude: 41.0082, longitude: 28.9784)

    static func load() -> (Coordinates, AppSettings, TimeZone) {
        guard let defaults = UserDefaults(suiteName: suiteName) else {
            let fallback = AppSettings(
                methodID: "mwl",
                locationMode: .automatic,
                manualCoordinates: defaultCoordinates,
                timeZoneMode: .system,
                autoDetectMethod: true
            )
            return (defaultCoordinates, fallback, .current)
        }

        let settings: AppSettings
        if let data = defaults.data(forKey: key),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings(
                methodID: "mwl",
                locationMode: .automatic,
                manualCoordinates: defaultCoordinates,
                timeZoneMode: .system,
                autoDetectMethod: true
            )
        }

        let coords: Coordinates
        if settings.locationMode == .automatic {
            if let data = defaults.data(forKey: "detectedCoordinates.v1"),
               let decoded = try? JSONDecoder().decode(Coordinates.self, from: data) {
                coords = decoded
            } else {
                coords = settings.manualCoordinates ?? defaultCoordinates
            }
        } else {
            coords = settings.manualCoordinates ?? defaultCoordinates
        }

        let tz = settings.timeZoneMode.timeZone
        return (coords, settings, tz)
    }
}

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> PrayerEntry {
        let (coords, settings, tz) = AppGroupSettingsLoader.load()
        return PrayerEntry(
            date: Date(),
            prayerTimes: nil,
            nextPrayer: .dhuhr,
            nextPrayerTime: Date().addingTimeInterval(3600),
            timeZone: tz,
            coordinates: coords,
            settings: settings
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> ()) {
        let (coords, settings, tz) = AppGroupSettingsLoader.load()
        let now = Date()
        let today = computeTimes(coords: coords, settings: settings, date: now, timeZone: tz)
        let next = today.next(after: now)
        let entry = PrayerEntry(
            date: now,
            prayerTimes: today,
            nextPrayer: next?.prayer,
            nextPrayerTime: next?.time,
            timeZone: tz,
            coordinates: coords,
            settings: settings
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let (coords, settings, tz) = AppGroupSettingsLoader.load()
        let now = Date()
        
        var entries: [PrayerEntry] = []
        
        let today = computeTimes(coords: coords, settings: settings, date: now, timeZone: tz)
        let tomorrow = computeTimes(coords: coords, settings: settings, date: now.addingTimeInterval(86400), timeZone: tz)
        
        let nextNow = today.next(after: now) ?? tomorrow.next(after: now)
        let entryNow = PrayerEntry(
            date: now,
            prayerTimes: today,
            nextPrayer: nextNow?.prayer,
            nextPrayerTime: nextNow?.time,
            timeZone: tz,
            coordinates: coords,
            settings: settings
        )
        entries.append(entryNow)
        
        let allTimes = Array(today.times.values) + Array(tomorrow.times.values)
        let upcomingTimes = allTimes.filter { $0 > now && $0.timeIntervalSince(now) < 86400 }.sorted()
        
        for time in upcomingTimes {
            let dayTimes = computeTimes(coords: coords, settings: settings, date: time, timeZone: tz)
            let nextDayTimes = computeTimes(coords: coords, settings: settings, date: time.addingTimeInterval(86400), timeZone: tz)
            let next = dayTimes.next(after: time) ?? nextDayTimes.next(after: time)
            let entry = PrayerEntry(
                date: time,
                prayerTimes: dayTimes,
                nextPrayer: next?.prayer,
                nextPrayerTime: next?.time,
                timeZone: tz,
                coordinates: coords,
                settings: settings
            )
            entries.append(entry)
        }
        
        for hour in 1...24 {
            let tickDate = now.addingTimeInterval(Double(hour) * 3600)
            if !entries.contains(where: { abs($0.date.timeIntervalSince(tickDate)) < 300 }) {
                let dayTimes = computeTimes(coords: coords, settings: settings, date: tickDate, timeZone: tz)
                let nextDayTimes = computeTimes(coords: coords, settings: settings, date: tickDate.addingTimeInterval(86400), timeZone: tz)
                let next = dayTimes.next(after: tickDate) ?? nextDayTimes.next(after: tickDate)
                let entry = PrayerEntry(
                    date: tickDate,
                    prayerTimes: dayTimes,
                    nextPrayer: next?.prayer,
                    nextPrayerTime: next?.time,
                    timeZone: tz,
                    coordinates: coords,
                    settings: settings
                )
                entries.append(entry)
            }
        }
        
        entries.sort { $0.date < $1.date }
        
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    private func computeTimes(coords: Coordinates, settings: AppSettings, date: Date, timeZone: TimeZone) -> PrayerTimes {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let comps = cal.dateComponents([.year, .month, .day], from: date)
        let params = MethodRegistry.resolve(
            methodID: settings.methodID,
            hanafiAsr: settings.hanafiAsr,
            manualParameters: settings.manualParameters
        )?.resolve(for: coords) ?? MWLAdapter().resolve(for: coords)
        
        let astronomical = PrayerTimeEngine.calculate(
            date: comps,
            coordinates: coords,
            params: params,
            timeZone: timeZone
        )
        
        if settings.calculationMode == .manual {
            let manual = ManualSchedule(
                jamaatMinutes: settings.jamaatTimes,
                azanBeforeJamaat: settings.azanBeforeJamaat,
                keepWaqt: settings.manualKeepWaqt
            )
            return manual.applied(to: astronomical, day: date, timeZone: timeZone)
        }
        
        return astronomical
    }
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let prayerTimes: PrayerTimes?
    let nextPrayer: Prayer?
    let nextPrayerTime: Date?
    let timeZone: TimeZone
    let coordinates: Coordinates
    let settings: AppSettings
}

struct PrayerTimesWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWidgetView(entry: entry)
        case .systemMedium:
            MediumWidgetView(entry: entry)
        default:
            SmallWidgetView(entry: entry)
        }
    }
}

struct SmallWidgetView: View {
    let entry: Provider.Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                if let next = entry.nextPrayer {
                    Image(systemName: PrayerFormatting.icon(next))
                        .font(.title2)
                        .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 0.247))
                        .padding(8)
                        .background(Color(red: 0.18, green: 0.58, blue: 0.247).opacity(0.12))
                        .clipShape(Circle())
                }
                Spacer()
                Image("Mosque")
                    .renderingMode(.template)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 0.247).opacity(0.3))
            }

            if let next = entry.nextPrayer, let nextTime = entry.nextPrayerTime {
                VStack(alignment: .leading, spacing: 2) {
                    Text(PrayerFormatting.name(next))
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(PrayerFormatting.clock(nextTime, in: entry.timeZone))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Text(nextTime, style: .timer)
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 0.247))
            } else {
                Text("No upcoming prayers")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .containerBackground(Color(.secondarySystemGroupedBackground), for: .widget)
    }
}

struct MediumWidgetView: View {
    let entry: Provider.Entry

    var body: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("UPCOMING")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(.secondary)

                if let next = entry.nextPrayer, let nextTime = entry.nextPrayerTime {
                    HStack {
                        Image(systemName: PrayerFormatting.icon(next))
                            .font(.headline)
                            .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 0.247))
                        
                        Text(PrayerFormatting.name(next))
                            .font(.headline)
                    }

                    Text(PrayerFormatting.clock(nextTime, in: entry.timeZone))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Text(nextTime, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundStyle(Color(red: 0.18, green: 0.58, blue: 0.247))
                } else {
                    Text("No upcoming prayers")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                if let times = entry.prayerTimes {
                    ForEach(Prayer.allCases, id: \.rawValue) { prayer in
                        let time = times.times[prayer]
                        let isNext = entry.nextPrayer == prayer
                        HStack {
                            Image(systemName: PrayerFormatting.icon(prayer))
                                .font(.caption)
                                .foregroundStyle(isNext ? Color(red: 0.18, green: 0.58, blue: 0.247) : .secondary)
                            
                            Text(PrayerFormatting.name(prayer))
                                .font(.caption)
                                .fontWeight(isNext ? .bold : .regular)
                                .foregroundStyle(isNext ? .primary : .secondary)

                            Spacer()

                            if let time = time {
                                Text(PrayerFormatting.clock(time, in: entry.timeZone))
                                    .font(.caption.monospacedDigit())
                                    .fontWeight(isNext ? .bold : .regular)
                                    .foregroundStyle(isNext ? Color(red: 0.18, green: 0.58, blue: 0.247) : .secondary)
                            }
                        }
                        .padding(.vertical, 2)
                    }
                } else {
                    Text("No prayer times loaded")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
        }
        .padding()
        .containerBackground(Color(.secondarySystemGroupedBackground), for: .widget)
    }
}

@main
struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times Widget")
        .description("View today's prayer times and countdown to the next prayer.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
