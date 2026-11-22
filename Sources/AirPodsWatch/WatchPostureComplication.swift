import SwiftUI
import WidgetKit

public struct WatchPostureTimelineEntry: TimelineEntry {
    public let date: Date
    public let postureScore: Int
    public let pitch: Double
    public let isSlouching: Bool
    
    public init(date: Date = Date(), postureScore: Int = 94, pitch: Double = -3.2, isSlouching: Bool = false) {
        self.date = date
        self.postureScore = postureScore
        self.pitch = pitch
        self.isSlouching = isSlouching
    }
}

public struct WatchPostureComplicationView: View {
    let entry: WatchPostureTimelineEntry
    @Environment(\.widgetFamily) var family
    
    public init(entry: WatchPostureTimelineEntry) {
        self.entry = entry
    }
    
    public var body: some View {
        switch family {
        case .accessoryCircular:
            ZStack {
                AccessoryWidgetBackground()
                VStack(spacing: 0) {
                    Image(systemName: entry.isSlouching ? "figure.walk.motion" : "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundColor(entry.isSlouching ? .orange : .green)
                    Text("\(entry.postureScore)%")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
            }
        case .accessoryCorner:
            Text("\(entry.postureScore)%")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(entry.isSlouching ? .orange : .green)
                #if os(watchOS)
                .widgetLabel {
                    Text(entry.isSlouching ? "Slouch" : "Aligned")
                }
                #endif
        case .accessoryRectangular:
            HStack(spacing: 6) {
                Image(systemName: "headphones")
                    .foregroundColor(entry.isSlouching ? .orange : .green)
                VStack(alignment: .leading, spacing: 1) {
                    Text("AirPods Posture: \(entry.postureScore)%")
                        .font(.system(size: 11, weight: .bold))
                    Text(entry.isSlouching ? "Head pitch \(Int(entry.pitch))° — Sit up" : "Neutral Cervical Spine")
                        .font(.system(size: 9))
                        .foregroundColor(.secondary)
                }
            }
        default:
            Text("\(entry.postureScore)%")
        }
    }
}
