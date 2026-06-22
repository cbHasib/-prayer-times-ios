import ActivityKit
import Foundation
import PrayerKit

public struct PrayerActivityAttributes: ActivityAttributes, Sendable {
    public struct ContentState: Codable, Hashable, Sendable {
        public var nextPrayerName: String
        public var nextPrayerTime: Date
        public var secondsUntilNext: TimeInterval
        
        public init(nextPrayerName: String, nextPrayerTime: Date, secondsUntilNext: TimeInterval) {
            self.nextPrayerName = nextPrayerName
            self.nextPrayerTime = nextPrayerTime
            self.secondsUntilNext = secondsUntilNext
        }
    }

    public var todayPrayers: [String: Date]
    
    public init(todayPrayers: [String: Date]) {
        self.todayPrayers = todayPrayers
    }
}
