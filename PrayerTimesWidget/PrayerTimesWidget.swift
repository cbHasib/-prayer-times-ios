import WidgetKit
import SwiftUI
import PrayerKit

struct AppGroupSettingsLoader {
    static let suiteName = "group.co.tareq.prayertimes"
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
        let (_, settings, tz) = AppGroupSettingsLoader.load()
        let today = PrayerTimes(date: Date(), times: [:])
        return PrayerEntry(
            date: Date(),
            today: today,
            tomorrow: today,
            timeZone: tz,
            settings: settings
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PrayerEntry) -> ()) {
        let (coords, settings, tz) = AppGroupSettingsLoader.load()
        let now = Date()
        let today = computeTimes(coords: coords, settings: settings, timeZone: tz, dayOffset: 0, reference: now)
        let tomorrow = computeTimes(coords: coords, settings: settings, timeZone: tz, dayOffset: 1, reference: now)
        
        let entry = PrayerEntry(
            date: now,
            today: today,
            tomorrow: tomorrow,
            timeZone: tz,
            settings: settings
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let (coords, settings, tz) = AppGroupSettingsLoader.load()
        let now = Date()
        let today = computeTimes(coords: coords, settings: settings, timeZone: tz, dayOffset: 0, reference: now)
        let tomorrow = computeTimes(coords: coords, settings: settings, timeZone: tz, dayOffset: 1, reference: now)

        var entries: [PrayerEntry] = []
        
        // Generate timeline snapshots at current time, and around each prayer time
        let snapshotDates = generateSnapshotDates(today: today, tomorrow: tomorrow, reference: now)
        for date in snapshotDates {
            let entryToday = computeTimes(coords: coords, settings: settings, timeZone: tz, dayOffset: 0, reference: date)
            let entryTomorrow = computeTimes(coords: coords, settings: settings, timeZone: tz, dayOffset: 1, reference: date)
            
            entries.append(PrayerEntry(
                date: date,
                today: entryToday,
                tomorrow: entryTomorrow,
                timeZone: tz,
                settings: settings
            ))
        }

        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
    }

    // MARK: Helpers

    private func computeTimes(coords: Coordinates, settings: AppSettings, timeZone: TimeZone, dayOffset: Int, reference: Date) -> PrayerTimes {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let day = cal.date(byAdding: .day, value: dayOffset, to: reference) ?? reference
        let comps = cal.dateComponents([.year, .month, .day], from: day)
        
        let resolvedAdapter = MethodRegistry.resolve(
            methodID: settings.methodID,
            hanafiAsr: settings.hanafiAsr,
            manualParameters: settings.manualParameters
        ) ?? MWLAdapter()
        
        var p = resolvedAdapter.resolve(for: coords)
        if settings.highLatitudeRule != .automatic {
            p.highLatitudeRule = settings.highLatitudeRule
        }
        
        let astronomical = PrayerTimeEngine.calculate(
            date: comps,
            coordinates: coords,
            params: p,
            timeZone: timeZone
        )
        
        if settings.calculationMode == .manual {
            let manual = ManualSchedule(
                jamaatMinutes: settings.jamaatTimes,
                azanBeforeJamaat: settings.azanBeforeJamaat,
                keepWaqt: settings.manualKeepWaqt
            )
            return manual.applied(to: astronomical, day: day, timeZone: timeZone)
        }
        
        return astronomical
    }

    private func generateSnapshotDates(today: PrayerTimes, tomorrow: PrayerTimes, reference: Date) -> [Date] {
        var dates = [reference]
        
        // Add all upcoming prayer times for today and tomorrow as refresh instants
        let allTimes = Array(today.times.values) + Array(tomorrow.times.values)
        for time in allTimes {
            if time > reference {
                dates.append(time)
                // Also refresh 1 minute after each prayer time to transition smoothly
                dates.append(time.addingTimeInterval(60))
            }
        }
        
        // Return sorted chronological unique dates
        return Array(Set(dates)).sorted()
    }
}

struct PrayerEntry: TimelineEntry {
    let date: Date
    let today: PrayerTimes
    let tomorrow: PrayerTimes
    let timeZone: TimeZone
    let settings: AppSettings

    var nextEvent: (prayer: Prayer, time: Date)? {
        today.next(after: date) ?? tomorrow.next(after: date)
    }
}

struct PrayerTimesWidgetEntryView : View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var family

    private static let brand = Color(red: 0.18, green: 0.58, blue: 0.247)

    var body: some View {
        switch family {
        case .systemSmall:
            smallWidgetView
        case .systemMedium:
            mediumWidgetView
        default:
            smallWidgetView
        }
    }

    // MARK: Small Widget Layout

    private var smallWidgetView: some View {
        VStack(spacing: 8) {
            if let next = entry.nextEvent {
                HStack(spacing: 8) {
                    Image(systemName: PrayerFormatting.icon(next.prayer))
                        .font(.headline)
                        .foregroundStyle(Self.brand)
                        .frame(width: 28, height: 28)
                        .background(Self.brand.opacity(0.12))
                        .clipShape(Circle())
                    
                    Text(PrayerFormatting.name(next.prayer))
                        .font(.headline)
                        .foregroundStyle(.primary)
                }
                
                Text(PrayerFormatting.clock(next.time, in: entry.timeZone))
                    .font(.system(size: 26, weight: .bold))
                    .foregroundStyle(Self.brand)
                
                // Native System live timer
                Text(next.time, style: .timer)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No prayers")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }

    // MARK: Medium Widget Layout

    private var mediumWidgetView: some View {
        HStack(spacing: 20) {
            // Left Half: Next prayer countdown
            VStack(alignment: .leading, spacing: 8) {
                if let next = entry.nextEvent {
                    HStack(spacing: 8) {
                        Image(systemName: PrayerFormatting.icon(next.prayer))
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(width: 32, height: 32)
                            .background(Self.brand)
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading, spacing: 1) {
                            Text(PrayerFormatting.name(next.prayer))
                                .font(.headline)
                                .foregroundStyle(.primary)
                            Text("Next prayer")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Text(PrayerFormatting.clock(next.time, in: entry.timeZone))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(Self.brand)
                    
                    Text(next.time, style: .timer)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundStyle(.secondary)
                } else {
                    Text("No prayers")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Divider()
            
            // Right Half: Today's list
            VStack(spacing: 4) {
                let nextPrayer = entry.nextEvent?.prayer
                ForEach(entry.today.ordered, id: \.prayer) { entry in
                    let isNext = nextPrayer == entry.prayer
                    HStack {
                        Image(systemName: PrayerFormatting.icon(entry.prayer))
                            .font(.caption2)
                            .foregroundStyle(isNext ? Self.brand : .secondary)
                            .frame(width: 16)
                        
                        Text(PrayerFormatting.name(entry.prayer))
                            .font(.system(size: 13, weight: isNext ? .semibold : .regular))
                            .foregroundStyle(isNext ? .primary : .secondary)
                        
                        Spacer()
                        
                        Text(PrayerFormatting.clock(entry.time, in: self.entry.timeZone))
                            .font(.system(size: 13, weight: isNext ? .semibold : .regular, design: .monospaced))
                            .foregroundStyle(isNext ? Self.brand : .secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(isNext ? Self.brand.opacity(0.08) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .frame(maxWidth: .infinity)
        }
        .containerBackground(for: .widget) {
            Color(.systemBackground)
        }
    }
}

struct PrayerTimesWidget: Widget {
    let kind: String = "PrayerTimesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            PrayerTimesWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Prayer Times")
        .description("View daily prayer times and next Salah countdown.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct ManualSchedule {
    var jamaatMinutes: [Prayer: Int]
    var azanBeforeJamaat: Int
    var keepWaqt: Bool

    func applied(to base: PrayerTimes, day: Date, timeZone: TimeZone) -> PrayerTimes {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = timeZone
        let midnight = cal.startOfDay(for: day)
        var times = base.times
        for prayer in Prayer.obligatory {
            guard let minutes = jamaatMinutes[prayer] else { continue }
            times[prayer] = midnight.addingTimeInterval(TimeInterval(minutes) * 60)
        }
        return PrayerTimes(date: base.date, times: times)
    }
}
