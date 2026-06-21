import Foundation

/// A geographic location used by the calculation engine. Elevation is optional
/// and only affects the sunrise/sunset horizon dip; defaults to sea level.
public struct Coordinates: Codable, Sendable, Equatable, Hashable {
    public var latitude: Double
    public var longitude: Double
    public var elevation: Double

    public init(latitude: Double, longitude: Double, elevation: Double = 0) {
        self.latitude = latitude
        self.longitude = longitude
        self.elevation = elevation
    }
}
