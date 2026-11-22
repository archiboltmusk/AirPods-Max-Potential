import Foundation
#if os(iOS) && canImport(ActivityKit)
import ActivityKit

public struct AirPodsPostureActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        public var pitch: Double
        public var roll: Double
        public var postureScore: Int
        public var isSlouching: Bool
        public var statusMessage: String
        public var sessionDurationSeconds: Int
        
        public init(
            pitch: Double,
            roll: Double,
            postureScore: Int,
            isSlouching: Bool,
            statusMessage: String,
            sessionDurationSeconds: Int
        ) {
            self.pitch = pitch
            self.roll = roll
            self.postureScore = postureScore
            self.isSlouching = isSlouching
            self.statusMessage = statusMessage
            self.sessionDurationSeconds = sessionDurationSeconds
        }
    }
    
    public var profileName: String
    public var userDeviceName: String
    
    public init(profileName: String = "Ergonomic Focus", userDeviceName: String = "AirPods Pro") {
        self.profileName = profileName
        self.userDeviceName = userDeviceName
    }
}
#endif
