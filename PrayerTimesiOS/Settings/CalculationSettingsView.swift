import SwiftUI
import PrayerKit

/// Calculation method settings — method picker, Asr school, high latitude rule, and manual schedules.
struct CalculationSettingsView: View {
    @Bindable var settings: SettingsStore

    private static let manualMethodID = "manual"
    private static let defaultManualParameters = CalculationParameters(fajrAngle: 18, ishaAngle: 17)

    var body: some View {
        List {
            Section {
                Picker("Time Source", selection: $settings.settings.calculationMode) {
                    Text("Calculated").tag(CalculationMode.calculated)
                    Text("Manual (Fixed)").tag(CalculationMode.manual)
                }
                .pickerStyle(.segmented)
            } header: {
                Text("Source")
            } footer: {
                Text(settings.settings.calculationMode == .calculated
                     ? "Times are computed astronomically from your location."
                     : "Times are taken from the fixed schedule you enter below — ideal where the mosque announces set jamaat times.")
            }

            if settings.settings.calculationMode == .calculated {
                calculatedSections
            } else {
                manualSections
            }
        }
        .navigationTitle("Calculation")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Calculated State

    @ViewBuilder
    private var calculatedSections: some View {
        Section {
            Toggle("Auto-detect method from location", isOn: autoDetectBinding)
        } header: {
            Text("Automation")
        } footer: {
            if let label = settings.autoMethodLabel {
                Text(label)
            } else {
                Text("Resolves your country to a method; you can still override it below.")
            }
        }

        if !settings.settings.autoDetectMethod {
            Section {
                Picker("Calculation Method", selection: methodBinding) {
                    ForEach(MethodRegistry.builtIn, id: \.id) { method in
                        Text(method.displayName).tag(method.id)
                    }
                    Text("Manual").tag(Self.manualMethodID)
                }
                .pickerStyle(.navigationLink)

                Picker("Asr (madhab)", selection: $settings.settings.hanafiAsr) {
                    Text("Standard (Shafiʿi)").tag(false)
                    Text("Hanafi").tag(true)
                }

                Picker("High Latitude Rule", selection: $settings.settings.highLatitudeRule) {
                    ForEach(HighLatitudeRule.allCases, id: \.self) { rule in
                        Text(PrayerFormatting.highLatitudeRuleName(rule)).tag(rule)
                    }
                }
                .pickerStyle(.navigationLink)
            } header: {
                Text("Juristic & High Latitude")
            }
        }

        if settings.settings.methodID == Self.manualMethodID && !settings.settings.autoDetectMethod {
            manualMethodEditorSection
        }
    }

    // MARK: Manual (fixed) State

    @ViewBuilder
    private var manualSections: some View {
        Section {
            Stepper(value: $settings.settings.azanBeforeJamaat, in: 0...60) {
                HStack {
                    Text("Adhan before jamaat")
                    Spacer()
                    Text(azanBeforeLabel).monospacedDigit().foregroundStyle(.secondary)
                }
            }
            Toggle(isOn: $settings.settings.manualKeepWaqt) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Follow waqt for Sunrise & windows")
                        .font(.body)
                    Text("Keep astronomical times for non-jamaat events.")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }
        } header: {
            Text("Adhan Timing")
        } footer: {
            Text("The Adhan reminder fires this many minutes before the jamaat time set below.")
        }

        Section {
            ForEach(Prayer.obligatory, id: \.self) { prayer in
                Stepper(value: jamaatBinding(for: prayer), in: 0...1439) {
                    HStack {
                        Text(PrayerFormatting.name(prayer))
                        Spacer()
                        Text(jamaatTimeLabel(for: prayer)).monospacedDigit().foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Jamaat Schedule")
        } footer: {
            Text("Times as announced by your mosque. The Adhan chip is the jamaat time minus the offset above.")
        }
    }

    private var azanBeforeLabel: String {
        let m = settings.settings.azanBeforeJamaat
        return m == 0 ? "At jamaat" : "\(m) min before"
    }

    private func jamaatTimeLabel(for prayer: Prayer) -> String {
        let minutes = settings.settings.jamaatTimes[prayer] ?? (AppSettings.defaultJamaatTimes[prayer] ?? 0)
        let hours = minutes / 60
        let mins = minutes % 60
        return String(format: "%02d:%02d", hours, mins)
    }

    // MARK: Manual Parameters Editor (Calculated -> Manual)

    @ViewBuilder
    private var manualMethodEditorSection: some View {
        Section {
            HStack {
                Text("Fajr angle")
                Spacer()
                TextField("Fajr angle", value: fajrAngleBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            Toggle("Isha as fixed minutes after Maghrib", isOn: ishaFixedToggle)

            if settings.settings.manualParameters?.ishaFixedMinutes != nil {
                Stepper(value: ishaFixedMinutesBinding, in: 0...150) {
                    HStack {
                        Text("Isha (min after Maghrib)")
                        Spacer()
                        Text("\(settings.settings.manualParameters?.ishaFixedMinutes ?? 90)").monospacedDigit().foregroundStyle(.secondary)
                    }
                }
            } else {
                HStack {
                    Text("Isha angle")
                    Spacer()
                    TextField("Isha angle", value: ishaAngleBinding, format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                }
            }

            HStack {
                Text("Sunrise/Maghrib horizon")
                Spacer()
                TextField("Horizon", value: sunriseAngleBinding, format: .number.precision(.fractionLength(0...2)))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 80)
            }

            Picker("Asr shadow factor", selection: shadowFactorBinding) {
                Text("Standard (1×)").tag(1.0)
                Text("Hanafi (2×)").tag(2.0)
            }
        } header: {
            Text("Manual Calculation Parameters")
        }

        Section {
            ForEach(Prayer.obligatory, id: \.self) { prayer in
                Stepper(value: offsetBinding(for: prayer), in: -60...60) {
                    HStack {
                        Text(PrayerFormatting.name(prayer))
                        Spacer()
                        let offset = settings.settings.manualParameters?.manualOffsets[prayer] ?? 0
                        Text("\(offset > 0 ? "+" : "")\(offset) min").monospacedDigit().foregroundStyle(.secondary)
                    }
                }
            }
        } header: {
            Text("Per-Prayer Offsets (Minutes)")
        }
    }

    // MARK: Bindings

    private var methodBinding: Binding<String> {
        Binding(
            get: { settings.settings.methodID },
            set: { newID in
                settings.settings.autoDetectMethod = false
                settings.settings.methodID = newID
                if newID == Self.manualMethodID, settings.settings.manualParameters == nil {
                    settings.settings.manualParameters = Self.defaultManualParameters
                }
            }
        )
    }

    private var autoDetectBinding: Binding<Bool> {
        Binding(
            get: { settings.settings.autoDetectMethod },
            set: { enabled in
                settings.settings.autoDetectMethod = enabled
                if enabled {
                    Task { await settings.detectLocation() }
                }
            }
        )
    }

    private func jamaatBinding(for prayer: Prayer) -> Binding<Int> {
        Binding(
            get: { settings.settings.jamaatTimes[prayer] ?? (AppSettings.defaultJamaatTimes[prayer] ?? 0) },
            set: { settings.settings.jamaatTimes[prayer] = $0 }
        )
    }

    private var fajrAngleBinding: Binding<Double> {
        Binding(
            get: { settings.settings.manualParameters?.fajrAngle ?? 18.0 },
            set: {
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                p.fajrAngle = $0
                settings.settings.manualParameters = p
            }
        )
    }

    private var ishaAngleBinding: Binding<Double> {
        Binding(
            get: { settings.settings.manualParameters?.ishaAngle ?? 17.0 },
            set: {
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                p.ishaAngle = $0
                settings.settings.manualParameters = p
            }
        )
    }

    private var ishaFixedMinutesBinding: Binding<Int> {
        Binding(
            get: { settings.settings.manualParameters?.ishaFixedMinutes ?? 90 },
            set: {
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                p.ishaFixedMinutes = $0
                settings.settings.manualParameters = p
            }
        )
    }

    private var ishaFixedToggle: Binding<Bool> {
        Binding(
            get: { settings.settings.manualParameters?.ishaFixedMinutes != nil },
            set: { useFixed in
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                if useFixed {
                    p.ishaFixedMinutes = p.ishaFixedMinutes ?? 90
                    p.ishaAngle = nil
                } else {
                    p.ishaFixedMinutes = nil
                    p.ishaAngle = p.ishaAngle ?? 17
                }
                settings.settings.manualParameters = p
            }
        )
    }

    private var sunriseAngleBinding: Binding<Double> {
        Binding(
            get: { settings.settings.manualParameters?.sunriseAngle ?? -0.833 },
            set: {
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                p.sunriseAngle = $0
                settings.settings.manualParameters = p
            }
        )
    }

    private var shadowFactorBinding: Binding<Double> {
        Binding(
            get: { settings.settings.manualParameters?.asrShadowFactor ?? 1.0 },
            set: {
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                p.asrShadowFactor = $0
                settings.settings.manualParameters = p
            }
        )
    }

    private func offsetBinding(for prayer: Prayer) -> Binding<Int> {
        Binding(
            get: { settings.settings.manualParameters?.manualOffsets[prayer] ?? 0 },
            set: {
                var p = settings.settings.manualParameters ?? Self.defaultManualParameters
                p.manualOffsets[prayer] = $0
                settings.settings.manualParameters = p
            }
        )
    }
}
