import SwiftUI
import AppKit

/// Unified Showcase & Control Center for Open-Source AirPods Innovations.
/// Synthesizes architectural breakthroughs from:
/// - crafter-station/posture (Dynamic Bending Menu Bar Spine Glyph)
/// - tldev/dorso (Progressive Multi-Display Radial Glow & Screen Blur Overlay)
/// - allenv0/AirPosture (5-Phase Cervical Rep Counter & Anti-Gaming Recovery Lockout)
/// - jaskirat1616/AirPoise (16-Gesture Action Engine & 1€ Adaptive IMU Filter)
/// - chandansgowda/posture-fix (Instant CoreAudio Output Monitor, 11 System Alert Sounds, Spoken Voice Coach & 7-Day History)
public struct OpenSourceUpgradesView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var spineGlyph = MotionManager.shared
    @ObservedObject var screenBlur = ProgressiveScreenBlurManager.shared
    @ObservedObject var repCounter = CervicalRepCounterEngine.shared
    @ObservedObject var gestureRunner = HeadShortcutsActionRunner.shared
    @ObservedObject var voiceAlert = SystemAudioVoiceAlertEngine.shared
    @ObservedObject var coreAudio = CoreAudioDeviceMonitor.shared
    @ObservedObject var historyStore = RollingPostureHistoryStore.shared

    @State private var selectedSubtab: UpgradeTab = .dorsoBlur

    public enum UpgradeTab: String, CaseIterable, Identifiable {
        case dorsoBlur = "Dorso Screen Blur"
        case crafterGlyph = "Crafter Spine Glyph"
        case airPostureReps = "AirPosture PT Reps"
        case airPoiseGestures = "AirPoise 16 Gestures"
        case postureFixSuite = "PostureFix Voice & History"

        public var id: String { rawValue }
        public var icon: String {
            switch self {
            case .dorsoBlur: return "sun.max.trianglebadge.exclamationmark"
            case .crafterGlyph: return "figure.seated.side"
            case .airPostureReps: return "repeat.circle.fill"
            case .airPoiseGestures: return "hand.raised.square.on.square.fill"
            case .postureFixSuite: return "waveform.badge.magnifyingglass"
            }
        }
    }

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero Header
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(LinearGradient(colors: [.indigo, .purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 64, height: 64)
                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Peer Open-Source Innovations")
                                .font(.title2.bold())
                            Text("6 Repos Unified")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(Color.purple.opacity(0.2)))
                                .foregroundColor(.purple)
                        }
                        Text("Synthesizing the best algorithms, visuals, and ergonomic protections across all top AirPods posture projects on GitHub.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(18)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                .cornerRadius(18)

                // Sub-navigation picker
                Picker("Innovation Suite", selection: $selectedSubtab) {
                    ForEach(UpgradeTab.allCases) { tab in
                        Label(tab.rawValue, systemImage: tab.icon).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 4)

                // Tab Content
                switch selectedSubtab {
                case .dorsoBlur:
                    dorsoScreenBlurSection
                case .crafterGlyph:
                    crafterSpineGlyphSection
                case .airPostureReps:
                    airPostureRepsSection
                case .airPoiseGestures:
                    airPoiseGesturesSection
                case .postureFixSuite:
                    postureFixSuiteSection
                }
            }
            .padding(20)
        }
    }

    // MARK: - 1. Dorso Progressive Screen Blur & Radial Vignette
    private var dorsoScreenBlurSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "Progressive Multi-Screen Blur & Vignette",
                badge: "tldev/dorso",
                badgeColor: .orange,
                desc: "Spans all connected monitors (NSScreen.screens). Smoothly darkens perimeter edges with a radial glow and applies progressive soft blur when slouching persists, compelling upright posture without abrupt popup interruptions."
            )

            Toggle("Enable Progressive Multi-Screen Blur & Vignette", isOn: $screenBlur.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Vignette Reach (Perimeter to Center):")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(screenBlur.reach * 100))%")
                        .font(.subheadline.bold())
                }
                Slider(value: $screenBlur.reach, in: 0.3...0.95, step: 0.05)

                HStack {
                    Text("Live Calculated Blur & Glow Intensity:")
                        .font(.subheadline)
                    Spacer()
                    Text("\(Int(screenBlur.blurIntensity * 100))%")
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundColor(screenBlur.blurIntensity > 0.4 ? .orange : .green)
                }
                ProgressView(value: screenBlur.blurIntensity, total: 1.0)
                    .tint(screenBlur.blurIntensity > 0.4 ? .orange : .green)

                Toggle("Include HUD Window Background Blur", isOn: $screenBlur.enableWindowBlur)
                    .font(.subheadline)

                HStack(spacing: 12) {
                    Button(action: {
                        screenBlur.previewTest(duration: 3.5)
                    }) {
                        Label("Trigger 3.5s Live Screen Blur Test", systemImage: "sparkles")
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Reset Overlays") {
                        screenBlur.rebuildOverlayWindows()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - 2. Crafter Spine Menu Bar Glyph
    private var crafterSpineGlyphSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "Live Bending Spine Menu Bar Glyph",
                badge: "crafter-station/posture",
                badgeColor: .blue,
                desc: "Procedural NSBezierPath seated ergonomic figure in the macOS menu bar. The spine curves dynamically with your exact head pitch and turns amber on slouch."
            )

            HStack(spacing: 30) {
                VStack(spacing: 8) {
                    Text("Live Menu Bar Preview")
                        .font(.caption.bold())
                        .foregroundColor(.secondary)

                    let tone: LiveSpineMenuBarGlyph.Tone = !motion.isConnected ? .disconnected : (motion.postureState == .slouching ? .alert : .calm)
                    let previewImage = LiveSpineMenuBarGlyph.image(
                        pitchDegrees: motion.deltaPitch,
                        tone: tone,
                        height: 36,
                        label: motion.isConnected ? "\(Int(motion.deltaPitch))°" : nil
                    )
                    Image(nsImage: previewImage)
                        .frame(width: 80, height: 44)
                        .padding(12)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(10)
                        .shadow(radius: 2)

                    Text(motion.isConnected ? "Pitch \(Int(motion.deltaPitch))°" : "AirPods Disconnected")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Dynamic Procedural Mechanics:")
                        .font(.subheadline.bold())
                    Text("• Hip anchored at ergonomic chair base point (X=5, Y=4.4)")
                        .font(.caption)
                    Text("• Spine Bézier curve flexes proportionally to min(abs(pitch)/35°, 1.0)")
                        .font(.caption)
                    Text("• Neck and head pivot forward & down as cervical angle drops")
                        .font(.caption)
                    Text("• Switches from template monochrome to alert orange on slouch")
                        .font(.caption)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - 3. AirPosture 5-Phase Rep Counter
    private var airPostureRepsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "5-Phase Cervical Physical Therapy Rep Counter",
                badge: "allenv0/AirPosture",
                badgeColor: .green,
                desc: "Kinematic exercise tracker: idle → entering → holding → completing → recovering. Enforces a 2.0s anti-gaming upright lockout to prevent false repetitions."
            )

            HStack {
                Picker("Exercise Routine", selection: $repCounter.currentExercise) {
                    ForEach(CervicalRepCounterEngine.ExerciseType.allCases) { ex in
                        Text(ex.rawValue).tag(ex)
                    }
                }
                .pickerStyle(.menu)

                Spacer()

                if repCounter.isSessionActive {
                    Button("Stop Session") {
                        repCounter.stopSession()
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                } else {
                    Button("Start PT Session") {
                        repCounter.startSession(exercise: repCounter.currentExercise)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }

            // Interactive Progress Gauge
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.primary.opacity(0.12), lineWidth: 14)
                        .frame(width: 140, height: 140)

                    Circle()
                        .trim(from: 0, to: CGFloat(repCounter.holdProgress))
                        .stroke(
                            repCounter.currentPhase == .holding ? Color.green : Color.blue,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 140, height: 140)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: repCounter.holdProgress)

                    VStack(spacing: 2) {
                        Text("\(repCounter.currentReps) / \(repCounter.targetReps)")
                            .font(.system(size: 26, weight: .heavy, design: .rounded))
                        Text("REPS")
                            .font(.caption2.bold())
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Status:")
                            .font(.subheadline)
                        Text(repCounter.currentPhase.rawValue)
                            .font(.subheadline.bold())
                            .foregroundColor(repCounter.currentPhase == .holding ? .green : (repCounter.currentPhase == .recovering ? .orange : .primary))
                    }

                    if repCounter.currentPhase == .recovering {
                        Text("Anti-Gaming Lockout: Return to neutral for \(String(format: "%.1f", repCounter.recoveryRemaining))s")
                            .font(.caption)
                            .foregroundColor(.orange)
                    } else {
                        Text("Target: \(Int(repCounter.currentExercise.targetAngle))° along \(repCounter.currentExercise.motionAxis)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("Hold Goal: \(Int(repCounter.holdDuration)) seconds")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("Total Today: \(repCounter.totalSessionReps) reps")
                            .font(.caption2.bold())
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - 4. AirPoise 16 Gestures
    private var airPoiseGesturesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "16-Cervical Head Gesture Shortcut Engine",
                badge: "jaskirat1616/AirPoise",
                badgeColor: .purple,
                desc: "High-precision head gesture recognition powered by a 1-Euro adaptive filter for zero micro-jitter, walking bounce rejection, and direct dispatch to Apple Shortcuts and Media HUD."
            )

            Toggle("Enable Head Gesture Actions", isOn: $gestureRunner.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Recognized Gesture:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(gestureRunner.lastDetectedGesture)
                        .font(.title3.bold())
                        .foregroundColor(.accentColor)
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("Action Executed:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(gestureRunner.lastExecutedAction)
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
            }
            .padding(14)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 8) {
                Text("Default Gesture Mappings:")
                    .font(.subheadline.bold())

                ForEach(HeadShortcutsActionRunner.GestureType.allCases.prefix(6)) { gesture in
                    HStack {
                        Text(gesture.rawValue)
                            .font(.subheadline)
                            .frame(width: 140, alignment: .leading)

                        Picker("", selection: Binding(
                            get: { gestureRunner.gestureMappings[gesture] ?? HeadShortcutsActionRunner.ActionTarget.none },
                            set: { gestureRunner.gestureMappings[gesture] = $0 }
                        )) {
                            ForEach(HeadShortcutsActionRunner.ActionTarget.allCases) { action in
                                Text(action.rawValue).tag(action)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
    }

    // MARK: - 5. PostureFix Voice Coach & 7-Day History
    private var postureFixSuiteSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "CoreAudio Listener, Spoken Voice Coach & 7-Day History",
                badge: "chandansgowda/posture-fix",
                badgeColor: .teal,
                desc: "Instant event-driven CoreAudio output listener, 11 native macOS alert sounds with preview, spoken voice nudge, and persistent 7-day posture compliance bar chart."
            )

            // CoreAudio Output Status
            HStack {
                Circle()
                    .fill(coreAudio.isHeadphonesConnected ? Color.green : Color.orange)
                    .frame(width: 10, height: 10)
                Text("Default Output: \(coreAudio.deviceName)")
                    .font(.subheadline.bold())
                Spacer()
                Text(coreAudio.isAirPodsOrBeats ? "AirPods / Beats Active" : "Non-AirPods Device")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(10)

            // Sound & Voice Controls
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Toggle("Play In-Ear Sound", isOn: $voiceAlert.isSoundEnabled)
                    Spacer()
                    Picker("Sound Effect", selection: $voiceAlert.selectedSoundName) {
                        ForEach(SystemAudioVoiceAlertEngine.availableSystemSounds, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 140)

                    Button("Preview Sound") {
                        voiceAlert.previewSound()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                HStack {
                    Toggle("Spoken Voice Prompt", isOn: $voiceAlert.isVoiceCueEnabled)
                    Spacer()
                    TextField("Voice Phrase", text: $voiceAlert.voiceCuePhrase)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 160)

                    Button("Preview Voice") {
                        voiceAlert.previewVoice()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)

            // 7-Day History Bar Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("7-Day Posture Compliance History")
                    .font(.headline)

                let days = historyStore.lastDays(7)
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(days) { d in
                        VStack(spacing: 6) {
                            Text("\(Int(d.goodPercent))%")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(d.goodPercent > 80 ? .green : .orange)

                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.primary.opacity(0.08))
                                    .frame(width: 24, height: 90)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(d.goodPercent > 80 ? Color.green : Color.orange)
                                    .frame(width: 24, height: CGFloat(d.goodPercent / 100.0) * 90)
                            }

                            Text(d.shortWeekday)
                                .font(.caption2.bold())
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .padding(16)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(12)
        }
        .padding(18)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(16)
    }
}

// MARK: - Reusable Card Header
struct CardHeader: View {
    let title: String
    let badge: String
    let badgeColor: Color
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(badge)
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(badgeColor.opacity(0.18)))
                    .foregroundColor(badgeColor)
            }
            Text(desc)
                .font(.caption)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
