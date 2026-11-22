import SwiftUI

public struct WatchPostureDashboardView: View {
    @State private var postureScore: Int = 92
    @State private var pitch: Double = -3.5
    @State private var sensitivityDegrees: Double = 12.0
    @State private var isSnoozed: Bool = false
    
    @ObservedObject var hapticSentinel = WatchHapticSentinel.shared
    
    public init() {}
    
    private var statusColor: Color {
        if postureScore >= 80 {
            return .green
        } else if postureScore >= 60 {
            return .orange
        } else {
            return .red
        }
    }
    
    public var body: some View {
        ScrollView {
            VStack(spacing: 8) {
                // Posture Score Ring with Mascot Icon
                ZStack {
                    Circle()
                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                        .frame(width: 84, height: 84)
                    
                    Circle()
                        .trim(from: 0.0, to: CGFloat(postureScore) / 100.0)
                        .stroke(
                            statusColor,
                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))
                        .frame(width: 84, height: 84)
                        .animation(.spring(), value: postureScore)
                    
                    VStack(spacing: 0) {
                        Text("\(postureScore)%")
                            .font(.system(size: 20, weight: .heavy, design: .rounded))
                            .foregroundColor(statusColor)
                        Text(String(format: "%.0f°", pitch))
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 4)
                
                // Digital Crown Sensitivity Tuner
                VStack(spacing: 2) {
                    HStack {
                        Image(systemName: "crown.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.yellow)
                        Text("Sensitivity: ±\(Int(sensitivityDegrees))°")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.secondary)
                    }
                }
                #if os(watchOS)
                .focusable()
                .digitalCrownRotation(
                    detent: $sensitivityDegrees,
                    from: 5.0,
                    through: 25.0,
                    by: 1.0,
                    sensitivity: .medium,
                    isContinuous: false
                )
                #endif
                
                // Watch Action Buttons
                HStack(spacing: 6) {
                    // Quick Calibrate
                    Button(action: {
                        pitch = 0.0
                        postureScore = 100
                        hapticSentinel.playSuccessTap()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "scope")
                                .font(.system(size: 12))
                            Text("Calibrate")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                    
                    // Phantom Tap Test
                    Button(action: {
                        hapticSentinel.playPhantomWristTap()
                    }) {
                        VStack(spacing: 2) {
                            Image(systemName: "hand.tap.fill")
                                .font(.system(size: 12))
                            Text("Test Tap")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                        .background(Color.purple.opacity(0.3))
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 4)
            }
        }
        .navigationTitle("AirPodsIQ")
    }
}
