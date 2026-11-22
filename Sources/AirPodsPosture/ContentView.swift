import SwiftUI
import AirPodsCore

/// AirPodsIQ: Complete Gold-Standard Architecture.
/// Organizes all 16 specialized hardware suites, clinical labs, ecosystem bridges,
/// and granular settings under 4 clean, structured categories.
public struct ContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var glance = GlanceAndLockAutoCalibrator.shared
    @ObservedObject var companion = FloatingMiniDeskCompanionManager.shared
    @ObservedObject var torqueEngine = CervicalSpineTorqueEngine.shared
    @ObservedObject var physioReport = ClinicalPhysioReportExporter.shared
    
    @AppStorage("appVisualTheme") var appVisualTheme: String = "humanCinema"
    @State private var selectedTab: TabItem = .posture
    
    public enum TabItem: String, CaseIterable, Identifiable {
        // SECTION 1: ESSENTIAL POSTURE & SLEEP
        case posture = "Posture Monitor"
        case sleepLab = "Sleep & Recovery Lab"
        case stretches = "Neck Stretches & Mobility"
        case timeline = "Activity Timeline"
        case radar = "Spatial 360° Radar"
        
        // SECTION 2: BIOMETRICS & PRO SUITES
        case vitality = "Biohacking & Vitality"
        case pro3Suite = "AirPods Pro 3 Suite"
        case sensors = "Hardware Sensors & Battery"
        case openSourceLab = "Peer Open-Source Labs"
        
        // SECTION 3: POWER INNOVATIONS
        case upgrades = "Power Upgrades Suite"
        case advanced = "Spatial Intelligence"
        case elite = "Elite Labs Suite"
        
        // SECTION 4: ECOSYSTEM & CONFIGURATION
        case ecosystem = "Ecosystem Bridges (Watch & Desk)"
        case audit = "Loophole & Tech Audit"
        case potential = "AirPods Potential Roadmap"
        case settings = "Settings & Preferences"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .posture: return "person.crop.artzone"
            case .sleepLab: return "moon.stars.fill"
            case .stretches: return "figure.mind.and.body"
            case .timeline: return "chart.xyaxis.line"
            case .radar: return "dot.radiowaves.left.and.right"
                
            case .vitality: return "heart.text.square.fill"
            case .pro3Suite: return "sparkles.tv.fill"
            case .sensors: return "earbuds.case.fill"
            case .openSourceLab: return "sparkles.rectangle.stack.fill"
                
            case .upgrades: return "sparkles.square.filled.on.square"
            case .advanced: return "wand.and.stars.inverse"
            case .elite: return "crown.fill"
                
            case .ecosystem: return "applewatch.and.arrow.forward"
            case .audit: return "checkmark.shield.fill"
            case .potential: return "sparkles"
            case .settings: return "gearshape.fill"
            }
        }
        
        public var iconColor: Color {
            switch self {
            case .posture: return .green
            case .sleepLab: return .indigo
            case .stretches: return .teal
            case .timeline: return .orange
            case .radar: return .blue
                
            case .vitality: return .pink
            case .pro3Suite: return .purple
            case .sensors: return .cyan
            case .openSourceLab: return .purple
                
            case .upgrades: return .yellow
            case .advanced: return .indigo
            case .elite: return .yellow
                
            case .ecosystem: return .blue
            case .audit: return .orange
            case .potential: return .pink
            case .settings: return .gray
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Adaptive Living Canvas: Warm Film Grain Noir vs Cupertino Metal Plasma
            if appVisualTheme == "humanCinema" {
                AnalogFilmGrainCanvasView(postureScore: motion.postureScore)
            } else {
                FluidChromaticCanvasView(postureScore: motion.postureScore)
                    .opacity(0.85)
            }
            
            NavigationSplitView {
                VStack(spacing: 0) {
                    List(selection: $selectedTab) {
                        Section("ESSENTIAL POSTURE & SLEEP") {
                            sidebarRow(.posture)
                            sidebarRow(.sleepLab)
                            sidebarRow(.stretches)
                            sidebarRow(.timeline)
                            sidebarRow(.radar)
                        }
                        
                        Section("BIOMETRICS & PRO SUITES") {
                            sidebarRow(.vitality)
                            sidebarRow(.pro3Suite)
                            sidebarRow(.sensors)
                            sidebarRow(.openSourceLab)
                        }
                        
                        Section("POWER INNOVATIONS") {
                            sidebarRow(.upgrades)
                            sidebarRow(.advanced)
                            sidebarRow(.elite)
                        }
                        
                        Section("ECOSYSTEM & CONFIGURATION") {
                            sidebarRow(.ecosystem)
                            sidebarRow(.audit)
                            sidebarRow(.potential)
                            sidebarRow(.settings)
                        }
                    }
                    .listStyle(.sidebar)
                    
                    Divider()
                        .opacity(0.4)
                    
                    // Sidebar Footer: Live Hardware Connection Indicator
                    HStack(spacing: 8) {
                        Circle()
                            .fill(motion.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(motion.isConnected ? (motion.isSimulated ? "Demo Simulation" : "AirPods Connected") : "Disconnected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if audioMonitor.isMicrophoneInUse {
                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption2)
                                Text("Mic Active")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .navigationTitle("AirPodsIQ")
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 320)
            } detail: {
                Group {
                    switch selectedTab {
                    // SECTION 1: ESSENTIAL POSTURE & SLEEP
                    case .posture:
                        ScrollView {
                            VStack(spacing: 18) {
                                // "Glance & Lock" Autonomous Auto-Calibrate Pill
                                if glance.glanceLockHoldProgress > 0 && glance.glanceLockHoldProgress < 1.0 {
                                    HStack(spacing: 8) {
                                        Image(systemName: "sparkles")
                                            .foregroundColor(.cyan)
                                        Text("Glance & Lock: Calibrating in \(Int(ceil((1.0 - glance.glanceLockHoldProgress) * 3.0)))s...")
                                            .font(.caption.bold())
                                            .foregroundColor(.cyan)
                                        ProgressView(value: glance.glanceLockHoldProgress, total: 1.0)
                                            .progressViewStyle(.linear)
                                            .tint(.cyan)
                                            .frame(width: 80)
                                    }
                                    .padding(8)
                                    .background(Color.cyan.opacity(0.12))
                                    .cornerRadius(8)
                                }
                                
                                // Hero Posture Visualizer with Hergé mascot
                                PostureVisualizerView(motion: motion)
                                
                                // Biomechanical Daily Heatmap
                                BiomechanicalHeatmapView()
                                
                                // Slouch-Proof Interlock Warning
                                if let interlock = motion.calibrationInterlockAlert {
                                    HStack(spacing: 8) {
                                        Image(systemName: "hand.raised.fill")
                                            .foregroundColor(.yellow)
                                        Text(interlock)
                                            .font(.caption.bold())
                                            .foregroundColor(.yellow)
                                        Spacer()
                                        Button("Dismiss") {
                                            motion.calibrationInterlockAlert = nil
                                        }
                                        .buttonStyle(.borderless)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    }
                                    .padding(10)
                                    .background(Color.yellow.opacity(0.12))
                                    .cornerRadius(10)
                                }
                                
                                // Action Strip
                                HStack(spacing: 12) {
                                    Button(action: {
                                        motion.calibrateCurrentPosture()
                                    }) {
                                        Label("Calibrate Upright", systemImage: "scope")
                                            .font(.headline)
                                            .padding(.vertical, 3)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .disabled(!motion.isConnected)
                                    
                                    Button(action: {
                                        companion.toggleCompanion()
                                    }) {
                                        Label(companion.isCompanionVisible ? "Hide Mascot" : "Float Posture Buddy", systemImage: "person.crop.artzone")
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    // Snooze Menu
                                    if motion.isSnoozed {
                                        Button(action: { motion.clearSnooze() }) {
                                            Label("Clear Snooze", systemImage: "play.circle")
                                        }
                                        .buttonStyle(.bordered)
                                    } else {
                                        Menu {
                                            Button("Snooze 5 mins") { motion.snooze(minutes: 5) }
                                            Button("Snooze 15 mins") { motion.snooze(minutes: 15) }
                                            Button("Snooze 30 mins") { motion.snooze(minutes: 30) }
                                        } label: {
                                            Label("Snooze", systemImage: "moon.zzz")
                                        }
                                    }
                                    
                                    Button(action: {
                                        motion.toggleSimulation()
                                    }) {
                                        Label(motion.isSimulated ? "Exit Demo" : "Try Demo", systemImage: "wand.and.stars")
                                    }
                                    .buttonStyle(.bordered)
                                    
                                    Spacer()
                                    
                                    Button("Reset Today's Stats") {
                                        motion.secondsTracked = 0
                                        motion.secondsGoodPosture = 0
                                        motion.secondsSlouching = 0
                                        motion.slouchEventCount = 0
                                    }
                                    .buttonStyle(.borderless)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                }
                                .padding(.horizontal, 4)
                                
                                // Kapandji Cervical Spine Torque & Biomechanical Disc Load Card
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        HStack(spacing: 6) {
                                            Image(systemName: "scalemass.fill")
                                                .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 15.0 ? .red : .green)
                                            Text("Cervical Spine Torque & C5–C7 Disc Compression")
                                                .font(.system(size: 13, weight: .bold))
                                                .foregroundColor(.primary)
                                        }
                                        Spacer()
                                        Text(torqueEngine.currentLoad.discCompressionRisk.rawValue)
                                            .font(.caption2.bold())
                                            .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 15.0 ? .orange : .green)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 3)
                                            .background(Color(NSColor.controlBackgroundColor))
                                            .clipShape(Capsule())
                                    }
                                    
                                    HStack(spacing: 16) {
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(alignment: .firstTextBaseline, spacing: 4) {
                                                Text(String(format: "%.1f", torqueEngine.currentLoad.effectiveLoadLbs))
                                                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                                                    .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 15.0 ? .orange : .primary)
                                                Text("lbs")
                                                    .font(.caption.bold())
                                                    .foregroundColor(.secondary)
                                                Text("(\(String(format: "%.1f", torqueEngine.currentLoad.effectiveLoadKg)) kg)")
                                                    .font(.caption2)
                                                    .foregroundColor(.secondary)
                                            }
                                            Text("Effective Neck Load")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Divider().frame(height: 36)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("+\(Int(torqueEngine.currentLoad.extraTorqueOverheadLbs)) lbs")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 0 ? .red : .green)
                                            Text("Extra Slouch Shear")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Divider().frame(height: 36)
                                        
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text("\(Int(torqueEngine.cumulativeDayTorquePoundHours))")
                                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                                .foregroundColor(.primary)
                                            Text("Cumulative lb-hours")
                                                .font(.caption2)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        // 1-Click Clinical PDF Report Exporter
                                        Button(action: {
                                            _ = physioReport.generateClinicalReportPDF()
                                        }) {
                                            HStack(spacing: 6) {
                                                Image(systemName: "doc.text.fill")
                                                    .foregroundColor(.blue)
                                                Text("Export Physio PDF")
                                                    .font(.system(size: 11, weight: .bold))
                                            }
                                            .padding(.horizontal, 10)
                                            .padding(.vertical, 6)
                                            .background(Color.blue.opacity(0.12))
                                            .cornerRadius(8)
                                        }
                                        .buttonStyle(.plain)
                                    }
                                    
                                    Text(torqueEngine.reliefCallToAction)
                                        .font(.caption)
                                        .foregroundColor(torqueEngine.currentLoad.extraTorqueOverheadLbs > 10.0 ? .orange : .secondary)
                                }
                                .padding(14)
                                .background(Color(NSColor.controlBackgroundColor).opacity(0.6))
                                .cornerRadius(14)
                            }
                            .padding(20)
                        }
                    case .sleepLab:
                        OvernightSleepRecoveryView()
                    case .stretches:
                        StretchCoachView(motion: motion)
                    case .timeline:
                        ScrollView {
                            BiometricTimelineScrubberView()
                                .padding(24)
                        }
                    case .radar:
                        ScrollView {
                            SpatialSoundstageRadarView()
                                .padding(.vertical, 16)
                        }
                        
                    // SECTION 2: BIOMETRICS & PRO SUITES
                    case .vitality:
                        BiohackingVitalityView()
                    case .pro3Suite:
                        AirPodsPro3SuiteView()
                    case .sensors:
                        AirPodsProSensorsView()
                    case .openSourceLab:
                        OpenSourceUpgradesView()
                        
                    // SECTION 3: POWER INNOVATIONS
                    case .upgrades:
                        UpgradesSuiteView()
                    case .advanced:
                        AdvancedUpgradesView()
                    case .elite:
                        EliteUpgradesView()
                        
                    // SECTION 4: ECOSYSTEM & CONFIGURATION
                    case .ecosystem:
                        EcosystemBridgesView()
                    case .audit:
                        AuditAndLoopholesView()
                    case .potential:
                        FeaturesHubView(motion: motion)
                    case .settings:
                        SettingsView(motion: motion)
                    }
                }
                .navigationTitle(selectedTab.rawValue)
                .toolbar {
                    ToolbarItemGroup(placement: .primaryAction) {
                        Button(action: {
                            companion.toggleCompanion()
                        }) {
                            Image(systemName: "person.crop.artzone")
                                .foregroundColor(companion.isCompanionVisible ? .green : .secondary)
                        }
                        .help("Float Posture Buddy on Desktop")
                        
                        Button(action: {
                            motion.calibrateCurrentPosture()
                        }) {
                            Image(systemName: "scope")
                        }
                        .disabled(!motion.isConnected)
                        .help("Calibrate neutral upright (⌘⇧C)")
                    }
                }
            }
            
            // Fullscreen 20-20-20 Break Overlay
            if breakTimer.isBreakActive {
                ZStack {
                    Color.black.opacity(0.85)
                        .edgesIgnoringSafeArea(.all)
                    
                    VStack(spacing: 18) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("20-20-20 Ergonomic Rest")
                            .font(.title.bold())
                        
                        Text("Look at an object at least 20 feet away.\nRoll your shoulders gently and take a deep breath.")
                            .font(.subheadline)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        
                        // Countdown Ring
                        ZStack {
                            Circle()
                                .stroke(Color.primary.opacity(0.15), lineWidth: 10)
                                .frame(width: 110, height: 110)
                            
                            Circle()
                                .trim(from: 0, to: CGFloat(breakTimer.activeBreakSeconds / breakTimer.breakDurationSeconds))
                                .stroke(Color.blue, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 110, height: 110)
                                .rotationEffect(.degrees(-90))
                            
                            Text("\(Int(ceil(breakTimer.breakDurationSeconds - breakTimer.activeBreakSeconds)))s")
                                .font(.system(.title, design: .rounded, weight: .heavy))
                        }
                        .padding(.vertical, 8)
                        
                        Button("Skip Break") {
                            breakTimer.completeBreak()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(32)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
                    .shadow(radius: 20)
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 1080, minHeight: 700)
    }
    
    @ViewBuilder
    private func sidebarRow(_ tab: TabItem) -> some View {
        NavigationLink(value: tab) {
            Label {
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .medium))
            } icon: {
                Image(systemName: tab.icon)
                    .foregroundColor(tab.iconColor)
            }
        }
    }
}
