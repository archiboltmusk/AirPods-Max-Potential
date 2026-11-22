import SwiftUI
import AirPodsCore
#if os(iOS) && canImport(ActivityKit)
import ActivityKit
#endif

public struct IOSPostureDashboardView: View {
    @State private var pitch: Double = -4.2
    @State private var roll: Double = 1.1
    @State private var postureScore: Int = 94
    @State private var isSlouching: Bool = false
    @State private var isLiveActivityActive: Bool = false
    @State private var selectedProfile: String = "Reading & Paperwork"
    
    @ObservedObject var healthSync = HealthKitPostureSync.shared
    @ObservedObject var screenDistance = TrueDepthScreenDistanceSentinel.shared
    @ObservedObject var pencilSentinel = ApplePencilIllustratorModeSentinel.shared
    @ObservedObject var transceiver = MultipeerEcosystemTransceiver.shared
    
    public init() {}
    
    private var cardBackground: Color {
        #if os(iOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return Color.secondary.opacity(0.12)
        #endif
    }
    
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Top Ecosystem Sync Header
                    HStack {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(transceiver.connectedPeerNames.isEmpty ? Color.green : Color.blue)
                                .frame(width: 8, height: 8)
                            Text(transceiver.connectedPeerNames.isEmpty ? "iPhone Standalone Mode" : "Synced with Mac Studio Hub")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        
                        // Active Profile Selector Pill
                        Menu {
                            Button("Desk Focus (Strict 10°)") { selectedProfile = "Desk Focus" }
                            Button("Reading & Paperwork (18°)") { selectedProfile = "Reading & Paperwork" }
                            Button("Standing Desk Mode") { selectedProfile = "Standing Desk" }
                            Button("Apple Pencil Drafting (+18°)") {
                                pencilSentinel.activatePencilDrawingSession()
                                selectedProfile = "Drafting Mode"
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Text(selectedProfile)
                                    .font(.system(size: 11, weight: .bold))
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.system(size: 9))
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(cardBackground)
                            .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 4)
                    
                    // Hero Mascot Avatar Card
                    ZStack {
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .fill(Color(red: 0.98, green: 0.97, blue: 0.93))
                            .overlay(
                                RoundedRectangle(cornerRadius: 28, style: .continuous)
                                    .stroke(statusColor.opacity(0.4), lineWidth: 2.5)
                            )
                            .shadow(color: statusColor.opacity(0.18), radius: 12, x: 0, y: 4)
                        
                        VStack(spacing: 12) {
                            // Top Alignment Badge
                            HStack {
                                Spacer()
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(statusColor)
                                        .frame(width: 7, height: 7)
                                    Text("\(postureScore)% Alignment")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                        .foregroundColor(statusColor)
                                }
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(Color.white.opacity(0.95))
                                .clipShape(Capsule())
                                .shadow(color: Color.black.opacity(0.08), radius: 2)
                            }
                            .padding(.horizontal, 14)
                            .padding(.top, 14)
                            
                            // Mascot Avatar Art
                            ZStack {
                                Circle()
                                    .fill(statusColor.opacity(0.12))
                                    .frame(width: 140, height: 140)
                                
                                Image(systemName: isSlouching ? "person.crop.circle.badge.exclamationmark" : "person.crop.circle.badge.checkmark")
                                    .font(.system(size: 72))
                                    .foregroundColor(statusColor)
                                    .rotationEffect(.degrees(pitch * 0.4))
                                    .animation(.spring(response: 0.4), value: pitch)
                            }
                            .frame(height: 140)
                            
                            // Dynamic Pitch & Angle Readout
                            HStack(spacing: 16) {
                                VStack {
                                    Text(String(format: "%.1f°", pitch))
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Head Pitch")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Divider().frame(height: 24)
                                VStack {
                                    Text(String(format: "%.1f°", roll))
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundColor(.primary)
                                    Text("Head Roll")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Divider().frame(height: 24)
                                VStack {
                                    Text(postureScore >= 80 ? "Optimal" : "Slouch")
                                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                                        .foregroundColor(statusColor)
                                    Text("Status")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            .padding(.bottom, 14)
                        }
                    }
                    .frame(height: 260)
                    .padding(.horizontal)
                    
                    // Quick Action Grid (One-Tap Controls)
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                        // Action 1: Zero-Calibrate Now
                        Button(action: {
                            pitch = 0.0
                            roll = 0.0
                            postureScore = 100
                            isSlouching = false
                        }) {
                            HStack {
                                Image(systemName: "scope")
                                    .font(.system(size: 18))
                                    .foregroundColor(.blue)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Zero-Calibrate")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Lock neutral baseline")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(cardBackground)
                            .cornerRadius(14)
                        }
                        
                        // Action 2: Trigger Apple Watch Phantom Tap
                        Button(action: {
                            transceiver.sendHapticCommandToWatchOrIPhone(HapticCommandPacket(style: .gentleTap))
                        }) {
                            HStack {
                                Image(systemName: "applewatch.radiowaves.left.and.right")
                                    .font(.system(size: 18))
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Wrist Phantom Tap")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("Test Watch haptic")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(cardBackground)
                            .cornerRadius(14)
                        }
                        
                        // Action 3: Dynamic Island Live Activity Toggle
                        Button(action: {
                            isLiveActivityActive.toggle()
                        }) {
                            HStack {
                                Image(systemName: isLiveActivityActive ? "dot.radiowaves.left.and.right" : "circle.dashed")
                                    .font(.system(size: 18))
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(isLiveActivityActive ? "Live Activity On" : "Dynamic Island")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("HUD in Island / Lock")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(cardBackground)
                            .cornerRadius(14)
                        }
                        
                        // Action 4: Find in Bed Sonar Radar
                        Button(action: {
                            // Triggers acoustic sonar
                        }) {
                            HStack {
                                Image(systemName: "waveform.badge.magnifyingglass")
                                    .font(.system(size: 18))
                                    .foregroundColor(.orange)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Find in Bed")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.primary)
                                    Text("2.4kHz Sonar Chime")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding(12)
                            .background(cardBackground)
                            .cornerRadius(14)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Apple HealthKit Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Image(systemName: "heart.fill")
                                .foregroundColor(.red)
                            Text("Apple Health Integration")
                                .font(.system(size: 14, weight: .bold))
                            Spacer()
                            Text(healthSync.isAuthorized ? "Connected" : "Sync Needed")
                                .font(.caption.bold())
                                .foregroundColor(healthSync.isAuthorized ? .green : .secondary)
                        }
                        
                        Text("Posture tracking sessions are automatically written as Mindful Minutes and Cervical Mobility samples into Apple Health.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if !healthSync.isAuthorized {
                            Button(action: {
                                Task {
                                    _ = await healthSync.requestAuthorization()
                                }
                            }) {
                                Text("Connect Apple Health")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                                    .background(Color.red)
                                    .cornerRadius(10)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(14)
                    .background(cardBackground)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                .padding(.bottom, 24)
            }
            .navigationTitle("AirPodsIQ")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
        }
    }
}
