import SwiftUI
import WidgetKit

#if canImport(ActivityKit)
import ActivityKit

public struct AirPodsPostureWidget: Widget {
    public init() {}
    
    public var body: some WidgetConfiguration {
        ActivityConfiguration(for: AirPodsPostureActivityAttributes.self) { context in
            // Lock Screen / StandBy Banner
            HStack(spacing: 14) {
                // Hergé Companion Art or Icon
                ZStack {
                    Circle()
                        .fill(context.state.isSlouching ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                        .frame(width: 46, height: 46)
                    Image(systemName: context.state.isSlouching ? "figure.walk.motion" : "checkmark.seal.fill")
                        .font(.system(size: 20))
                        .foregroundColor(context.state.isSlouching ? .red : .green)
                }
                
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text(context.attributes.profileName)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primary)
                        Spacer()
                        Text("\(context.state.postureScore)%")
                            .font(.system(size: 16, weight: .heavy, design: .rounded))
                            .foregroundColor(context.state.isSlouching ? .orange : .green)
                    }
                    
                    Text(context.state.statusMessage)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                    
                    // Pitch Slouch Meter
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            Capsule().fill(Color.secondary.opacity(0.2))
                            Capsule()
                                .fill(context.state.isSlouching ? Color.orange : Color.green)
                                .frame(width: max(0, min(geo.size.width, geo.size.width * CGFloat(context.state.postureScore) / 100.0)))
                        }
                    }
                    .frame(height: 5)
                }
            }
            .padding(14)
            .background(Color(.systemBackground))
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Dynamic Island
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: "headphones")
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading) {
                            Text(context.attributes.userDeviceName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text("\(Int(context.state.pitch))° Pitch")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(context.state.isSlouching ? .orange : .primary)
                        }
                    }
                    .padding(.leading, 8)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    VStack(alignment: .trailing) {
                        Text("Alignment")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Text("\(context.state.postureScore)%")
                            .font(.system(size: 18, weight: .heavy, design: .rounded))
                            .foregroundColor(context.state.isSlouching ? .orange : .green)
                    }
                    .padding(.trailing, 8)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    HStack {
                        Circle()
                            .fill(context.state.isSlouching ? Color.red : Color.green)
                            .frame(width: 8, height: 8)
                        Text(context.state.statusMessage)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                        Spacer()
                        Text(formatDuration(context.state.sessionDurationSeconds))
                            .font(.caption.monospacedDigit())
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.bottom, 6)
                }
            } compactLeading: {
                // Compact Leading: Headphone icon or posture state
                Image(systemName: context.state.isSlouching ? "exclamationmark.triangle.fill" : "headphones")
                    .foregroundColor(context.state.isSlouching ? .orange : .green)
            } compactTrailing: {
                // Compact Trailing: Alignment percentage
                Text("\(context.state.postureScore)%")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(context.state.isSlouching ? .orange : .green)
            } minimal: {
                // Minimal: Live glowing circle
                Circle()
                    .fill(context.state.isSlouching ? Color.orange : Color.green)
                    .frame(width: 12, height: 12)
            }
        }
    }
    
    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}
#endif
