import SwiftUI
import AppKit

/// Unified Showcase & Control Center for Open-Source AirPods Innovations.
/// Synthesizes architectural breakthroughs from 6 top repositories:
/// - KaranSud/slouchguard (Dual-Direction Slouch vs Lounge, 24h Diurnal Fatigue)
/// - tldev/dorso (Progressive Multi-Display Radial Glow & Soft Screen Blur)
/// - crafter-station/posture (Dynamic Bending Menu Bar Spine Bézier Glyph)
/// - allenv0/AirPosture (5-Phase Cervical PT Rep Counter & Anti-Gaming Lockout)
/// - jaskirat1616/AirPoise (16-Gesture Action Engine & 1€ Adaptive IMU Filter)
/// - chandansgowda/posture-fix (Instant CoreAudio Listener, 11 System Sounds, Voice Cue, 7-Day History)
public struct OpenSourceUpgradesView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var screenBlur = ProgressiveScreenBlurManager.shared
    @ObservedObject var repCounter = CervicalRepCounterEngine.shared
    @ObservedObject var gestureRunner = HeadShortcutsActionRunner.shared
    @ObservedObject var voiceAlert = SystemAudioVoiceAlertEngine.shared
    @ObservedObject var coreAudio = CoreAudioDeviceMonitor.shared
    @ObservedObject var historyStore = RollingPostureHistoryStore.shared
    @ObservedObject var dualDirection = DualDirectionPosturalEngine.shared
    @ObservedObject var fatigueProfiler = HourlyFatigueProfiler.shared

    @State private var selectedSubtab: UpgradeTab = .slouchGuardSuite
    @State private var exportStatusMessage: String? = nil

    public enum UpgradeTab: String, CaseIterable, Identifiable {
        case slouchGuardSuite = "SlouchGuard"
        case dorsoBlur = "Dorso Blur"
        case crafterGlyph = "Crafter Spine"
        case airPostureReps = "AirPosture PT"
        case airPoiseGestures = "AirPoise 16"
        case postureFixSuite = "PostureFix Voice"

        public var id: String { rawValue }

        public var repoName: String {
            switch self {
            case .slouchGuardSuite: return "KaranSud/slouchguard"
            case .dorsoBlur: return "tldev/dorso"
            case .crafterGlyph: return "crafter-station/posture"
            case .airPostureReps: return "allenv0/AirPosture"
            case .airPoiseGestures: return "jaskirat1616/AirPoise"
            case .postureFixSuite: return "chandansgowda/posture-fix"
            }
        }

        public var icon: String {
            switch self {
            case .slouchGuardSuite: return "arrow.up.and.down.and.sparkles"
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
            VStack(alignment: .leading, spacing: 20) {
                // Hero Header Card (HUMAN.md Noir styling)
                HStack(spacing: 16) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        HumanCinemaDesignSystem.Palette.vermilion,
                                        HumanCinemaDesignSystem.Palette.emberAmber
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 58, height: 58)
                            .shadow(color: HumanCinemaDesignSystem.Palette.vermilion.opacity(0.35), radius: 10, x: 0, y: 4)

                        Image(systemName: "sparkles.rectangle.stack.fill")
                            .font(.system(size: 26))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Text("Peer Open-Source Innovations")
                                .font(.system(size: 20, weight: .bold, design: .serif))
                                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)

                            Text("6 REPOSITORIES UNIFIED")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(HumanCinemaDesignSystem.Palette.vermilion.opacity(0.2)))
                                .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                        }

                        Text("Synthesizing algorithms, ergonomics, and tactile feedback from the top AirPods projects on GitHub.")
                            .font(.system(size: 12))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                            .lineLimit(2)
                    }
                    Spacer()
                }
                .padding(18)
                .humanFilmCard(borderGlow: HumanCinemaDesignSystem.Palette.vermilion.opacity(0.35))

                // Sleek Flowing Pill Dock (Fixes the ugly truncated segmented picker!)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(UpgradeTab.allCases) { tab in
                            let isSelected = selectedSubtab == tab
                            Button(action: {
                                withAnimation(.interpolatingSpring(stiffness: 300, damping: 25)) {
                                    selectedSubtab = tab
                                }
                            }) {
                                HStack(spacing: 6) {
                                    Image(systemName: tab.icon)
                                        .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                                    Text(tab.rawValue)
                                        .font(.system(size: 12, weight: isSelected ? .bold : .medium, design: .rounded))
                                }
                                .foregroundColor(isSelected ? .white : HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(
                                    ZStack {
                                        if isSelected {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(
                                                    LinearGradient(
                                                        colors: [
                                                            HumanCinemaDesignSystem.Palette.vermilion,
                                                            HumanCinemaDesignSystem.Palette.vermilion.opacity(0.85)
                                                        ],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .shadow(color: HumanCinemaDesignSystem.Palette.vermilion.opacity(0.35), radius: 8, x: 0, y: 3)
                                        } else {
                                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                .fill(HumanCinemaDesignSystem.Palette.charcoal)
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                                        .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.6)
                                                )
                                        }
                                    }
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 2)
                    .padding(.vertical, 4)
                }

                // Active Tab Content
                Group {
                    switch selectedSubtab {
                    case .slouchGuardSuite:
                        slouchGuardSection
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
                .transition(.opacity.combined(with: .scale(scale: 0.98)))
            }
            .padding(22)
        }
    }

    // MARK: - 1. SlouchGuard Dual-Direction & Diurnal Fatigue
    private var slouchGuardSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "Dual-Direction Alignment & Diurnal Fatigue",
                badge: "KaranSud/slouchguard",
                badgeColor: HumanCinemaDesignSystem.Palette.vermilion,
                desc: "Differentiates forward slouch (text neck) from backward lounge (chair slump). Tracks 24-hour diurnal fatigue patterns to isolate your peak slump window."
            )

            // Current Direction Badge
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE BIOMECHANICAL ALIGNMENT")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    HStack(spacing: 8) {
                        Circle()
                            .fill(dualDirection.currentDirection == .optimal ? Color.green : (dualDirection.currentDirection == .forwardSlouch ? Color.red : HumanCinemaDesignSystem.Palette.vermilion))
                            .frame(width: 9, height: 9)
                        Text(dualDirection.currentDirection.rawValue)
                            .font(.system(size: 15, weight: .bold, design: .serif))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text("ACTIVE CORRECTIONS")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    Text("\(dualDirection.correctionsCount) resets")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)

            // Slouch vs Lounge Metrics Cards
            HStack(spacing: 14) {
                // Forward Slouch
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.down.forward.circle.fill")
                            .foregroundColor(.red)
                        Text("Forward Slouch")
                            .font(.subheadline.bold())
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    }
                    Text("Head dropping toward screen (Pitch < -\(Int(dualDirection.forwardSlouchThreshold))°)")
                        .font(.caption2)
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.65))

                    HStack {
                        Text("\(dualDirection.forwardSlouchCount) events")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                        Spacer()
                        Text(String(format: "%.1fm", dualDirection.totalSlouchSeconds / 60.0))
                            .font(.caption.bold())
                            .foregroundColor(.red)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(Color.red.opacity(0.2), lineWidth: 0.6))

                // Backward Lounge
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "arrow.up.backward.circle.fill")
                            .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                        Text("Backward Lounge")
                            .font(.subheadline.bold())
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    }
                    Text("Slumping into chair backrest (Pitch > +\(Int(dualDirection.backwardLoungeThreshold))°)")
                        .font(.caption2)
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.65))

                    HStack {
                        Text("\(dualDirection.backwardLoungeCount) events")
                            .font(.system(.headline, design: .rounded))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                        Spacer()
                        Text(String(format: "%.1fm", dualDirection.totalLoungeSeconds / 60.0))
                            .font(.caption.bold())
                            .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(HumanCinemaDesignSystem.Palette.vermilion.opacity(0.08))
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(HumanCinemaDesignSystem.Palette.vermilion.opacity(0.2), lineWidth: 0.6))
            }

            // Slouch vs Lounge Split Ratio Bar
            VStack(alignment: .leading, spacing: 8) {
                let split = dualDirection.slouchVsLoungeSplit
                HStack {
                    Text("POSTURAL BIAS RATIO")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    Spacer()
                    Text("\(Int(split.slouchPercent))% Forward  •  \(Int(split.loungePercent))% Backward")
                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                }

                GeometryReader { geo in
                    HStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.red)
                            .frame(width: max(4, geo.size.width * CGFloat(split.slouchPercent / 100.0)))
                        RoundedRectangle(cornerRadius: 3)
                            .fill(HumanCinemaDesignSystem.Palette.vermilion)
                            .frame(width: max(4, geo.size.width * CGFloat(split.loungePercent / 100.0)))
                    }
                }
                .frame(height: 7)
            }
            .padding(14)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)

            // 24-Hour Diurnal Fatigue Profiler
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("24-Hour Diurnal Fatigue Distribution")
                            .font(.system(size: 14, weight: .bold, design: .serif))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                        Text("Peak Slump Window: \(fatigueProfiler.peakFatigueHourString)")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.emberAmber)
                    }
                    Spacer()

                    Button(action: {
                        if let url = fatigueProfiler.exportCSV() {
                            exportStatusMessage = "CSV exported: \(url.lastPathComponent)"
                            NSWorkspace.shared.activateFileViewerSelecting([url])
                        }
                    }) {
                        Label("Export CSV", systemImage: "arrow.down.doc")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                if let status = exportStatusMessage {
                    Text(status)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }

                // 24-Hour Bar Chart
                HStack(alignment: .bottom, spacing: 3) {
                    ForEach(0..<24, id: \.self) { h in
                        let sec = fatigueProfiler.hourlyPoorSeconds[h]
                        let maxSec = max(1.0, fatigueProfiler.hourlyPoorSeconds.max() ?? 1.0)
                        let heightNorm = min(1.0, sec / maxSec)

                        VStack(spacing: 3) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(h == fatigueProfiler.peakFatigueHour ? HumanCinemaDesignSystem.Palette.vermilion : (sec > 0 ? HumanCinemaDesignSystem.Palette.emberAmber.opacity(0.8) : Color.white.opacity(0.08)))
                                .frame(height: max(4, CGFloat(heightNorm) * 60))

                            Text(h % 3 == 0 ? "\(h)" : "")
                                .font(.system(size: 8, design: .monospaced))
                                .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
                .frame(height: 75)
                .padding(.top, 6)

                // Conversational AI Prompt / Stats Button
                HStack {
                    Button(action: {
                        let summary = fatigueProfiler.generateConversationalSummary()
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(summary, forType: .string)
                        exportStatusMessage = "Summary copied to clipboard!"
                    }) {
                        Label("Copy Daily Posture Summary", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.borderless)
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)

                    Spacer()

                    Text("~/Library/Application Support/AirPodsIQ/stats/")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
        }
        .padding(18)
        .humanFilmCard(borderGlow: HumanCinemaDesignSystem.Palette.vermilion.opacity(0.24))
    }

    // MARK: - 2. Dorso Progressive Screen Blur & Radial Vignette
    private var dorsoScreenBlurSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "Progressive Multi-Screen Blur & Vignette",
                badge: "tldev/dorso",
                badgeColor: HumanCinemaDesignSystem.Palette.emberAmber,
                desc: "Spans all connected monitors (NSScreen.screens). Smoothly darkens perimeter edges with a radial glow and applies progressive soft blur when slouching persists, compelling upright posture without abrupt popup interruptions."
            )

            Toggle("Enable Progressive Multi-Screen Blur & Vignette", isOn: $screenBlur.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)

            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Text("Vignette Reach (Perimeter to Center):")
                        .font(.subheadline)
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    Spacer()
                    Text("\(Int(screenBlur.reach * 100))%")
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.emberAmber)
                }
                Slider(value: $screenBlur.reach, in: 0.3...0.95, step: 0.05)
                    .tint(HumanCinemaDesignSystem.Palette.emberAmber)

                HStack {
                    Text("Live Calculated Blur & Glow Intensity:")
                        .font(.subheadline)
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    Spacer()
                    Text("\(Int(screenBlur.blurIntensity * 100))%")
                        .font(.system(.subheadline, design: .monospaced, weight: .bold))
                        .foregroundColor(screenBlur.blurIntensity > 0.4 ? HumanCinemaDesignSystem.Palette.vermilion : .green)
                }
                ProgressView(value: screenBlur.blurIntensity, total: 1.0)
                    .tint(screenBlur.blurIntensity > 0.4 ? HumanCinemaDesignSystem.Palette.vermilion : .green)

                Toggle("Include HUD Window Background Blur", isOn: $screenBlur.enableWindowBlur)
                    .font(.subheadline)
                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)

                HStack(spacing: 12) {
                    Button(action: {
                        screenBlur.previewTest(duration: 3.5)
                    }) {
                        Label("Trigger 3.5s Live Screen Blur Test", systemImage: "sparkles")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(HumanCinemaDesignSystem.Palette.vermilion)

                    Button("Reset Overlays") {
                        screenBlur.rebuildOverlayWindows()
                    }
                    .buttonStyle(.bordered)
                    .font(.system(size: 12))
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
        }
        .padding(18)
        .humanFilmCard(borderGlow: HumanCinemaDesignSystem.Palette.emberAmber.opacity(0.24))
    }

    // MARK: - 3. Crafter Spine Menu Bar Glyph
    private var crafterSpineGlyphSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "Live Bending Spine Menu Bar Glyph",
                badge: "crafter-station/posture",
                badgeColor: Color.blue,
                desc: "Procedural NSBezierPath seated ergonomic figure in the macOS menu bar. The spine curves dynamically with your exact head pitch and turns amber on slouch."
            )

            HStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text("LIVE MENU BAR GLYPH")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)

                    let tone: LiveSpineMenuBarGlyph.Tone = !motion.isConnected ? .disconnected : (motion.postureState == .slouching ? .alert : .calm)
                    let previewImage = LiveSpineMenuBarGlyph.image(
                        pitchDegrees: motion.deltaPitch,
                        tone: tone,
                        height: 38,
                        label: motion.isConnected ? "\(Int(motion.deltaPitch))°" : nil
                    )
                    Image(nsImage: previewImage)
                        .frame(width: 86, height: 48)
                        .padding(10)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.white.opacity(0.1), lineWidth: 0.8))

                    Text(motion.isConnected ? "Pitch \(Int(motion.deltaPitch))°" : "AirPods Offline")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Dynamic Procedural Mechanics:")
                        .font(.system(size: 13, weight: .bold, design: .serif))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    Text("• Hip anchored at ergonomic chair base point (X=5, Y=4.4)")
                        .font(.system(size: 11))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                    Text("• Spine Bézier curve flexes proportionally to pitch deviation")
                        .font(.system(size: 11))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                    Text("• Neck and head pivot forward & down as cervical angle drops")
                        .font(.system(size: 11))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                    Text("• Automatically switches from template monochrome to alert orange on slouch")
                        .font(.system(size: 11))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
        }
        .padding(18)
        .humanFilmCard(borderGlow: Color.blue.opacity(0.24))
    }

    // MARK: - 4. AirPosture 5-Phase Rep Counter
    private var airPostureRepsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "5-Phase Cervical Physical Therapy Rep Counter",
                badge: "allenv0/AirPosture",
                badgeColor: Color.green,
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
                    .tint(HumanCinemaDesignSystem.Palette.vermilion)
                }
            }

            // Interactive Progress Gauge
            HStack(spacing: 24) {
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.08), lineWidth: 14)
                        .frame(width: 130, height: 130)

                    Circle()
                        .trim(from: 0, to: CGFloat(repCounter.holdProgress))
                        .stroke(
                            repCounter.currentPhase == .holding ? Color.green : HumanCinemaDesignSystem.Palette.vermilion,
                            style: StrokeStyle(lineWidth: 14, lineCap: .round)
                        )
                        .frame(width: 130, height: 130)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 0.1), value: repCounter.holdProgress)

                    VStack(spacing: 2) {
                        Text("\(repCounter.currentReps)/\(repCounter.targetReps)")
                            .font(.system(size: 24, weight: .heavy, design: .serif))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                        Text("REPS")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("STATUS:")
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                        Text(repCounter.currentPhase.rawValue)
                            .font(.system(size: 13, weight: .bold, design: .serif))
                            .foregroundColor(repCounter.currentPhase == .holding ? .green : (repCounter.currentPhase == .recovering ? HumanCinemaDesignSystem.Palette.emberAmber : HumanCinemaDesignSystem.Palette.parchment))
                    }

                    if repCounter.currentPhase == .recovering {
                        Text("Anti-Gaming Lockout: Hold neutral for \(String(format: "%.1f", repCounter.recoveryRemaining))s")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.emberAmber)
                    } else {
                        Text("Target: \(Int(repCounter.currentExercise.targetAngle))° along \(repCounter.currentExercise.motionAxis)")
                            .font(.caption)
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                    }

                    HStack {
                        Text("Hold Goal: \(Int(repCounter.holdDuration)) seconds")
                            .font(.system(size: 11))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                        Spacer()
                        Text("Today: \(repCounter.totalSessionReps) reps")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                    }
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
        }
        .padding(18)
        .humanFilmCard(borderGlow: Color.green.opacity(0.24))
    }

    // MARK: - 5. AirPoise 16 Gestures
    private var airPoiseGesturesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "16-Cervical Head Gesture Action Runner",
                badge: "jaskirat1616/AirPoise",
                badgeColor: Color.purple,
                desc: "High-precision head gesture recognition powered by a 1-Euro adaptive filter for zero micro-jitter, walking bounce rejection, and direct dispatch to Apple Shortcuts and Media HUD."
            )

            Toggle("Enable Head Gesture Actions", isOn: $gestureRunner.isEnabled)
                .toggleStyle(.switch)
                .font(.headline)
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)

            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LAST RECOGNIZED GESTURE")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    Text(gestureRunner.lastDetectedGesture)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                }
                Divider()
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACTION EXECUTED")
                        .font(.system(size: 9, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    Text(gestureRunner.lastExecutedAction)
                        .font(.system(size: 16, weight: .bold, design: .serif))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                }
            }
            .padding(14)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)

            VStack(alignment: .leading, spacing: 10) {
                Text("Default Gesture Mappings:")
                    .font(.system(size: 12, weight: .bold, design: .serif))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)

                ForEach(HeadShortcutsActionRunner.GestureType.allCases.prefix(6)) { gesture in
                    HStack {
                        Text(gesture.rawValue)
                            .font(.system(size: 12, design: .monospaced))
                            .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
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
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
        }
        .padding(18)
        .humanFilmCard(borderGlow: Color.purple.opacity(0.24))
    }

    // MARK: - 6. PostureFix Voice Coach & 7-Day History
    private var postureFixSuiteSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            CardHeader(
                title: "CoreAudio Listener, Spoken Voice Coach & 7-Day History",
                badge: "chandansgowda/posture-fix",
                badgeColor: Color.teal,
                desc: "Instant event-driven CoreAudio output listener, 11 native macOS alert sounds with preview, spoken voice nudge, and persistent 7-day posture compliance bar chart."
            )

            // CoreAudio Output Status
            HStack {
                Circle()
                    .fill(coreAudio.isHeadphonesConnected ? Color.green : HumanCinemaDesignSystem.Palette.emberAmber)
                    .frame(width: 9, height: 9)
                Text("Default Output: \(coreAudio.deviceName)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                Spacer()
                Text(coreAudio.isAirPodsOrBeats ? "AirPods / Beats Active" : "Non-AirPods Device")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
            }
            .padding(12)
            .background(Color.black.opacity(0.35))
            .cornerRadius(10)

            // Sound & Voice Controls
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Toggle("Play In-Ear Sound", isOn: $voiceAlert.isSoundEnabled)
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    Spacer()
                    Picker("Sound Effect", selection: $voiceAlert.selectedSoundName) {
                        ForEach(SystemAudioVoiceAlertEngine.availableSystemSounds, id: \.self) { s in
                            Text(s).tag(s)
                        }
                    }
                    .pickerStyle(.menu)
                    .frame(width: 130)

                    Button("Preview") {
                        voiceAlert.previewSound()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }

                HStack {
                    Toggle("Spoken Voice Prompt", isOn: $voiceAlert.isVoiceCueEnabled)
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                    Spacer()
                    TextField("Voice Phrase", text: $voiceAlert.voiceCuePhrase)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 150)

                    Button("Preview Voice") {
                        voiceAlert.previewVoice()
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(16)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)

            // 7-Day History Bar Chart
            VStack(alignment: .leading, spacing: 12) {
                Text("7-Day Posture Compliance History")
                    .font(.system(size: 14, weight: .bold, design: .serif))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)

                let days = historyStore.lastDays(7)
                HStack(alignment: .bottom, spacing: 14) {
                    ForEach(days) { d in
                        VStack(spacing: 6) {
                            Text("\(Int(d.goodPercent))%")
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .foregroundColor(d.goodPercent > 80 ? .green : HumanCinemaDesignSystem.Palette.emberAmber)

                            ZStack(alignment: .bottom) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.08))
                                    .frame(width: 24, height: 90)

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(d.goodPercent > 80 ? Color.green : HumanCinemaDesignSystem.Palette.emberAmber)
                                    .frame(width: 24, height: CGFloat(d.goodPercent / 100.0) * 90)
                            }

                            Text(d.shortWeekday)
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .padding(16)
            .background(Color.black.opacity(0.35))
            .cornerRadius(12)
        }
        .padding(18)
        .humanFilmCard(borderGlow: Color.teal.opacity(0.24))
    }
}

// MARK: - Reusable Card Header (HUMAN.md Editorial Styling)
struct CardHeader: View {
    let title: String
    let badge: String
    let badgeColor: Color
    let desc: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .bold, design: .serif))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                Spacer()
                Text(badge)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(badgeColor.opacity(0.2)))
                    .foregroundColor(badgeColor)
            }
            Text(desc)
                .font(.system(size: 11))
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.72))
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(3)
        }
    }
}
