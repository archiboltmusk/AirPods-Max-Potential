import SwiftUI

public struct AirPodsProSensorsView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioDevice = AudioDeviceManager.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header
                HStack {
                    Image(systemName: "earbuds.case.fill")
                        .font(.title)
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("AirPods Pro 2 Sensor Telemetry")
                            .font(.title2.bold())
                        Text("Real-time 60Hz 6-axis IMU kinematic stream & hardware status")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(motion.packetCount > 0 ? Color.green : Color.orange)
                            .frame(width: 8, height: 8)
                        Text(motion.packetCount > 0 ? "Streaming 60Hz" : "Waiting for Stream")
                            .font(.caption.bold())
                            .foregroundColor(motion.packetCount > 0 ? .green : .orange)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color(NSColor.controlBackgroundColor))
                    .clipShape(Capsule())
                }
                
                // Hardware Connection & Audio Routing Notice
                if !audioDevice.isAirPodsActiveOutput {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.title3)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Audio Output Not Routed to AirPods")
                                .font(.headline)
                                .foregroundColor(.orange)
                            Text("Your Mac's active audio output is currently '\(audioDevice.currentOutputDeviceName)'. Apple's H2 chip in AirPods Pro 2 activates full-speed 60Hz sensor streaming when audio is routed to your AirPods.")
                                .font(.caption)
                                .foregroundColor(.primary)
                            
                            HStack(spacing: 8) {
                                Text("Tip: Click Sound in macOS Control Center and select your AirPods.")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                            }
                            .padding(.top, 2)
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(12)
                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.orange.opacity(0.3), lineWidth: 1))
                }
                
                // Stream Stats Pill Strip
                HStack(spacing: 12) {
                    SensorStatCard(title: "Packets Received", value: "\(motion.packetCount)", icon: "antenna.radiowaves.left.and.right", color: .green)
                    SensorStatCard(title: "Kinetic Energy", value: String(format: "%.3f g", motion.totalKineticEnergy), icon: "flame.fill", color: .orange)
                    SensorStatCard(title: "Audio Route", value: audioDevice.currentOutputDeviceName, icon: "headphones", color: audioDevice.isAirPodsActiveOutput ? .blue : .secondary)
                }
                
                // Sensor Section 1: Gravity Vector
                SensorSectionBox(title: "Earth's Gravity Vector (Tilt Acceleration)", icon: "globe.americas.fill", subtitle: "Total Earth gravity magnitude = 1.0g. Directly measures absolute head orientation.") {
                    HStack(spacing: 16) {
                        AxisBarView(label: "Gx (Lateral)", value: motion.gravityX, unit: "g", range: -1.0...1.0, color: .purple)
                        AxisBarView(label: "Gy (Forward)", value: motion.gravityY, unit: "g", range: -1.0...1.0, color: .blue)
                        AxisBarView(label: "Gz (Vertical)", value: motion.gravityZ, unit: "g", range: -1.0...1.0, color: .teal)
                    }
                }
                
                // Sensor Section 2: User Dynamic Acceleration
                SensorSectionBox(title: "User Acceleration (Dynamic Movement)", icon: "figure.walk.motion", subtitle: "Isolates active head motion from gravity. Detects nods, walking, and head gestures.") {
                    HStack(spacing: 16) {
                        AxisBarView(label: "Ax (Nodding)", value: motion.userAccelX, unit: "g", range: -0.5...0.5, color: .red)
                        AxisBarView(label: "Ay (Sway)", value: motion.userAccelY, unit: "g", range: -0.5...0.5, color: .green)
                        AxisBarView(label: "Az (Bobbing)", value: motion.userAccelZ, unit: "g", range: -0.5...0.5, color: .orange)
                    }
                }
                
                // Sensor Section 3: Gyroscope Angular Velocity
                SensorSectionBox(title: "Tri-Axial Gyroscope (Rotation Rate)", icon: "rotate.3d", subtitle: "Measures instantaneous angular rotational velocity in degrees per second.") {
                    HStack(spacing: 16) {
                        AxisBarView(label: "Pitch Rate (X)", value: motion.rotRateX, unit: "°/s", range: -60.0...60.0, color: .indigo)
                        AxisBarView(label: "Roll Rate (Y)", value: motion.rotRateY, unit: "°/s", range: -60.0...60.0, color: .cyan)
                        AxisBarView(label: "Yaw Rate (Z)", value: motion.rotRateZ, unit: "°/s", range: -60.0...60.0, color: .mint)
                    }
                }
                
                // Sensor Section 4: Spatial Quaternion
                SensorSectionBox(title: "4D Spatial Attitude Quaternion", icon: "cube.transparent", subtitle: "Singularity-free 4D representation of your AirPods Pro orientation in space.") {
                    HStack(spacing: 14) {
                        QuatPill(label: "qw", value: motion.quatW)
                        QuatPill(label: "qx", value: motion.quatX)
                        QuatPill(label: "qy", value: motion.quatY)
                        QuatPill(label: "qz", value: motion.quatZ)
                    }
                }
            }
            .padding(20)
        }
    }
}

struct SensorStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            Text(value)
                .font(.system(.headline, design: .monospaced, weight: .bold))
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(10)
    }
}

struct SensorSectionBox<Content: View>: View {
    let title: String
    let icon: String
    let subtitle: String
    let content: Content
    
    init(title: String, icon: String, subtitle: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.icon = icon
        self.subtitle = subtitle
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(.accentColor)
                Text(title)
                    .font(.headline)
            }
            Text(subtitle)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            content
                .padding(.top, 4)
        }
        .padding(14)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primary.opacity(0.06), lineWidth: 1))
    }
}

struct AxisBarView: View {
    let label: String
    let value: Double
    let unit: String
    let range: ClosedRange<Double>
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.caption2.bold())
                Spacer()
                Text(String(format: "%+.2f %@", value, unit))
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.primary.opacity(0.08))
                    
                    let halfW = geo.size.width / 2.0
                    let span = (range.upperBound - range.lowerBound) / 2.0
                    let clamped = max(range.lowerBound, min(range.upperBound, value))
                    let width = abs(clamped / span) * halfW
                    let startX = value >= 0 ? halfW : (halfW - width)
                    
                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: max(2, width), height: geo.size.height)
                        .offset(x: startX)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
    }
}

struct QuatPill: View {
    let label: String
    let value: Double
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.bold())
                .foregroundColor(.secondary)
            Text(String(format: "%+.3f", value))
                .font(.system(.subheadline, design: .monospaced, weight: .bold))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background(Color.primary.opacity(0.04))
        .cornerRadius(8)
    }
}
