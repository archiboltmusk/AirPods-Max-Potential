import SwiftUI

public struct AirPodsProSensorsView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioDevice = AudioDeviceManager.shared
    @ObservedObject var batteryOpt = AirPodsBatteryOptimizerEngine.shared
    @ObservedObject var tmjGuard = JawClenchingBruxismDetector.shared
    @ObservedObject var pomodoro = PostureGatedPomodoroEngine.shared
    
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
                        Text("AirPods Pro 2 & Max Hardware Diagnostics")
                            .font(.title2.bold())
                        Text("Smart Hz Battery Optimizer • TMJ Jaw Guard • Posture Pomodoro")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(batteryOpt.isEcoSamplingActive ? Color.teal : Color.green)
                            .frame(width: 8, height: 8)
                        Text(batteryOpt.isEcoSamplingActive ? "10Hz Eco-Pulse" : "60Hz Full Kinematics")
                            .font(.caption.bold())
                            .foregroundColor(batteryOpt.isEcoSamplingActive ? .teal : .green)
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
                        }
                    }
                    .padding(14)
                    .background(Color.orange.opacity(0.12))
                    .cornerRadius(12)
                }
                
                // Section 1: AirPods & Mac Battery Longevity ("Smart Hz" Eco Duty Cycle)
                SensorSectionBox(
                    title: "Smart Hz Battery Optimization & Bilateral Power Balance",
                    icon: "battery.100.bolt",
                    subtitle: "Throttles IMU radio transmission from 60Hz down to 10Hz during resting stillness. Saves up to 65% transmit power, extending AirPods sessions from 4.5h to 7h+."
                ) {
                    VStack(spacing: 12) {
                        // Live Connected Device Banner & Manual Refresh
                        HStack {
                            if !batteryOpt.deviceName.isEmpty {
                                HStack(spacing: 5) {
                                    Circle()
                                        .fill(Color.green)
                                        .frame(width: 7, height: 7)
                                    Text(batteryOpt.deviceName)
                                        .font(.system(size: 11, weight: .semibold))
                                        .foregroundColor(.primary)
                                    Text("• Live Hardware Telemetry")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                }
                            } else {
                                Text("Polling AirPods Battery...")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                batteryOpt.refreshHardwareBattery()
                            }) {
                                HStack(spacing: 4) {
                                    Image(systemName: "arrow.clockwise")
                                        .rotationEffect(.degrees(batteryOpt.isRefreshing ? 360 : 0))
                                    Text(batteryOpt.isRefreshing ? "Refreshing..." : "Refresh")
                                }
                                .font(.system(size: 10, weight: .medium))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.mini)
                            .disabled(batteryOpt.isRefreshing)
                        }
                        
                        HStack(spacing: 16) {
                            // Left Bud
                            VStack(spacing: 4) {
                                Image(systemName: "earbuds")
                                    .font(.title3)
                                    .foregroundColor(.cyan)
                                Text("Left: \(batteryOpt.leftDisplayString)")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.secondary.opacity(0.06))
                            .cornerRadius(8)
                            
                            // Right Bud
                            VStack(spacing: 4) {
                                Image(systemName: "earbuds")
                                    .font(.title3)
                                    .foregroundColor(.cyan)
                                Text("Right: \(batteryOpt.rightDisplayString)")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.secondary.opacity(0.06))
                            .cornerRadius(8)
                            
                            // Case
                            VStack(spacing: 4) {
                                Image(systemName: "case")
                                    .font(.title3)
                                    .foregroundColor(.green)
                                Text("Case: \(batteryOpt.caseDisplayString)")
                                    .font(.caption.bold())
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.secondary.opacity(0.06))
                            .cornerRadius(8)
                            
                            // Remaining Time
                            VStack(spacing: 4) {
                                Text(String(format: "%.1fh", batteryOpt.estimatedHoursRemaining))
                                    .font(.system(size: 20, weight: .bold, design: .rounded))
                                    .foregroundColor(.primary)
                                Text("Est. Remaining")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(10)
                            .background(Color.secondary.opacity(0.06))
                            .cornerRadius(8)
                        }
                        
                        if let alert = batteryOpt.quickChargeAdvisorAlert {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.fill")
                                    .foregroundColor(.orange)
                                Text(alert)
                                    .font(.caption.bold())
                                    .foregroundColor(.orange)
                            }
                            .padding(10)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.orange.opacity(0.12))
                            .cornerRadius(8)
                        }
                        
                        HStack {
                            Toggle("Enable Smart Hz Adaptive Duty Cycle", isOn: $batteryOpt.isSmartHzEnabled)
                                .font(.caption.bold())
                            Spacer()
                            Text("Current: \(batteryOpt.currentSamplingHz)Hz (\(batteryOpt.powerSaveRatioPercent)% TX Energy Saved)")
                                .font(.caption2.bold())
                                .foregroundColor(.teal)
                        }
                    }
                }
                
                // Section 2: Posture-Gated Pomodoro Focus Engine
                SensorSectionBox(
                    title: "Posture-Gated Pomodoro Deep Work Focus Engine",
                    icon: "timer",
                    subtitle: "A 25-minute deep work timer that ONLY counts down when your posture score is >= 80%. When you slouch, it pauses and pulses amber."
                ) {
                    VStack(spacing: 12) {
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 2) {
                                let mins = Int(pomodoro.secondsRemaining) / 60
                                let secs = Int(pomodoro.secondsRemaining) % 60
                                Text(String(format: "%02d:%02d", mins, secs))
                                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                                    .foregroundColor(pomodoro.isPosturePaused ? .orange : (pomodoro.isRunning ? .green : .primary))
                                
                                Text(pomodoro.isPosturePaused ? "⚠️ Slouching: Timer Paused!" : (pomodoro.isRunning ? "Focused Upright Flow" : "Ready to Start"))
                                    .font(.caption.bold())
                                    .foregroundColor(pomodoro.isPosturePaused ? .orange : .secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(Int(pomodoro.uprightFocusMinutesEarned))m Upright Today")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.green)
                                Text("\(pomodoro.completedSessionsToday) Sessions Completed")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            HStack(spacing: 8) {
                                if !pomodoro.isRunning {
                                    Button("Start Focus") {
                                        pomodoro.startSession()
                                    }
                                    .buttonStyle(.borderedProminent)
                                } else {
                                    Button("Pause") {
                                        pomodoro.pauseSession()
                                    }
                                    .buttonStyle(.bordered)
                                }
                                
                                Button("Reset") {
                                    pomodoro.resetSession()
                                }
                                .buttonStyle(.borderless)
                                .font(.caption)
                            }
                        }
                    }
                }
                
                // Section 3: Jaw Clenching & Bruxism Strain Guard
                SensorSectionBox(
                    title: "Jaw Clenching & Bruxism Strain Guard (TMJ Stress Detector)",
                    icon: "mouth.fill",
                    subtitle: "Detects bone-conducted high-frequency micro-tremors (120Hz-240Hz) from masseter and temporalis muscle clenching during stress."
                ) {
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(tmjGuard.tmjStressIndex)/100")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(tmjGuard.tmjStressIndex > 40 ? .orange : .green)
                            Text("TMJ Stress Index")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(tmjGuard.clenchEventsToday)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("Clench Events Today")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Text(tmjGuard.statusMessage)
                            .font(.caption.bold())
                            .foregroundColor(tmjGuard.jawClenchingActive ? .orange : .secondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                // Section 4: Live Kinematic Accelerometers & Gyroscopes
                SensorSectionBox(
                    title: "User Dynamic Acceleration (g units)",
                    icon: "speedometer",
                    subtitle: "Instantaneous dynamic linear acceleration isolating user head motion from Earth gravity"
                ) {
                    VStack(spacing: 10) {
                        AxisBarView(label: "X (Lateral)", value: motion.userAccelX, unit: "g", range: -1.0...1.0, color: .green)
                        AxisBarView(label: "Y (Vertical)", value: motion.userAccelY, unit: "g", range: -1.0...1.0, color: .blue)
                        AxisBarView(label: "Z (Sagittal)", value: motion.userAccelZ, unit: "g", range: -1.0...1.0, color: .orange)
                    }
                }
                
                SensorSectionBox(
                    title: "Rotation Rate / Gyroscope (deg/s)",
                    icon: "gyroscope",
                    subtitle: "Cervical angular velocity computed directly from AirPods H2 DSP"
                ) {
                    VStack(spacing: 10) {
                        AxisBarView(label: "Pitch Rate (Up/Down)", value: motion.rotRateX, unit: "°/s", range: -180.0...180.0, color: .purple)
                        AxisBarView(label: "Roll Rate (Tilt)", value: motion.rotRateY, unit: "°/s", range: -180.0...180.0, color: .pink)
                        AxisBarView(label: "Yaw Rate (Turn)", value: motion.rotRateZ, unit: "°/s", range: -180.0...180.0, color: .indigo)
                    }
                }
                
                SensorSectionBox(
                    title: "Spatial Attitude Quaternion",
                    icon: "cube.transparent",
                    subtitle: "Unit quaternion representation (w, x, y, z) ensuring gimbal-lock-free 3D orientation"
                ) {
                    HStack(spacing: 12) {
                        QuatPill(label: "qw", value: motion.quatW)
                        QuatPill(label: "qx", value: motion.quatX)
                        QuatPill(label: "qy", value: motion.quatY)
                        QuatPill(label: "qz", value: motion.quatZ)
                    }
                }
            }
            .padding(20)
        }
        .onAppear {
            batteryOpt.refreshHardwareBattery()
        }
    }
}

// MARK: - Supporting Component Views

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
