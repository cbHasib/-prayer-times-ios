import SwiftUI
import PrayerKit

/// Location & timezone settings.
struct LocationSettingsView: View {
    let settings: SettingsStore

    var body: some View {
        List {
            Section {
                Picker("Location Mode", selection: Binding(
                    get: { settings.settings.locationMode },
                    set: { settings.setLocationMode($0) }
                )) {
                    Text("Automatic").tag(LocationMode.automatic)
                    Text("Manual").tag(LocationMode.manual)
                }
                .pickerStyle(.segmented)

                if settings.settings.locationMode == .automatic {
                    if settings.isDetectingLocation {
                        HStack {
                            ProgressView()
                                .controlSize(.small)
                            Text("Detecting location…")
                                .foregroundStyle(.secondary)
                        }
                    } else if let error = settings.locationError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundStyle(.red)
                    } else if let coords = settings.detectedCoordinates {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Latitude: \(String(format: "%.4f", coords.latitude))")
                            Text("Longitude: \(String(format: "%.4f", coords.longitude))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Button("Re-detect Location") {
                        Task { await settings.detectLocation() }
                    }
                    .disabled(settings.isDetectingLocation)
                }
            } header: {
                Text("Location")
            }

            if settings.settings.locationMode == .manual {
                Section {
                    HStack {
                        Text("Latitude")
                        Spacer()
                        TextField("Lat", value: Binding(
                            get: { settings.settings.manualCoordinates?.latitude ?? 0 },
                            set: {
                                var coords = settings.settings.manualCoordinates ?? SettingsStore.defaultCoordinates
                                coords = Coordinates(latitude: $0, longitude: coords.longitude, elevation: coords.elevation)
                                settings.settings.manualCoordinates = coords
                            }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                    }

                    HStack {
                        Text("Longitude")
                        Spacer()
                        TextField("Lon", value: Binding(
                            get: { settings.settings.manualCoordinates?.longitude ?? 0 },
                            set: {
                                var coords = settings.settings.manualCoordinates ?? SettingsStore.defaultCoordinates
                                coords = Coordinates(latitude: coords.latitude, longitude: $0, elevation: coords.elevation)
                                settings.settings.manualCoordinates = coords
                            }
                        ), format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                    }
                } header: {
                    Text("Coordinates")
                }
            }

            if let warning = settings.timeZoneMismatchWarning {
                Section {
                    Label(warning, systemImage: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }
        }
        .navigationTitle("Location & Time")
        .navigationBarTitleDisplayMode(.inline)
    }
}
