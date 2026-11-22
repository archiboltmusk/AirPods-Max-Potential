import SwiftUI

/// AirPodsIQ: Modern 4-Hub Consolidated Architecture.
/// Replaces 18 scattered tabs with 4 Apple-grade, focused hubs:
/// 1. Posture & Desk (Live Hergé Mascot, 360° Radar, 24h Timeline)
/// 2. Sleep & Recovery (Clinical 10-Feature Sleep Suite)
/// 3. Focus & Mobility (40Hz Gamma Audio, Guided Stretches, Heart Rate)
/// 4. Settings & Shields (Meeting Auto-Mute, In-Case Standby, Diagnostics)
public struct ContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var glance = GlanceAndLockAutoCalibrator.shared
    @ObservedObject var companion = FloatingMiniDeskCompanionManager.shared
    
    @AppStorage("appVisualTheme") var appVisualTheme: String = "humanCinema"
    @State private var selectedTab: TabItem = .posture
    
    // Sub-segment states for clean navigation without cognitive clutter
    @State private var postureSubTab: Int = 0 // 0: Live Mascot, 1: 360° Radar, 2: 24h Timeline
    @State private var focusSubTab: Int = 0   // 0: Guided Stretches, 1: 40Hz Focus Audio, 2: Heart Rate & Vitals
    @State private var settingsSubTab: Int = 0 // 0: Shields & Preferences, 1: Diagnostics & Audit
    
    public enum TabItem: String, CaseIterable, Identifiable {
        case posture = "Posture & Desk"
        case sleepLab = "Sleep & Recovery"
        case focusMobility = "Focus & Mobility"
        case settings = "Settings & Shields"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .posture: return "person.crop.artzone"
            case .sleepLab: return "moon.stars.fill"
            case .focusMobility: return "waveform.path.badge.plus"
            case .settings: return "shield.lefthalf.filled"
            }
        }
        
        public var iconColor: Color {
            switch self {
            case .posture: return .green
            case .sleepLab: return .indigo
            case .focusMobility: return .teal
            case .settings: return .orange
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
                        Section("ESSENTIAL HUBS") {
                            sidebarRow(.posture)
                            sidebarRow(.sleepLab)
                            sidebarRow(.focusMobility)
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
                        Text(motion.isConnected ? (motion.isSimulated ? "Demo Mode" : "AirPods Active") : "Disconnected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        if audioMonitor.isMicrophoneInUse {
                            HStack(spacing: 4) {
                                Image(systemName: "mic.fill")
                                    .foregroundColor(.purple)
                                    .font(.caption2)
                                Text("In Call")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.purple)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .navigationTitle("AirPodsIQ")
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
            } detail: {
                Group {
                    switch selectedTab {
                    // HUB 1: POSTURE & DESK
                    case .posture:
                        VStack(spacing: 0) {
                            Picker("", selection: $postureSubTab) {
                                Text("Live Posture").tag(0)
                                Text("360° Spatial Radar").tag(1)
                                Text("24h Activity Timeline").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 10)
                            
                            Divider()
                            
                            if postureSubTab == 0 {
                                ScrollView {
                                    VStack(spacing: 18) {
                                        // "Glance & Lock" Autonomous Auto-Calibrate Pill
                                        if glance.glanceLockHoldProgress > 0 && glance.glanceLockHoldProgress < 1.0 {
                                            HStack(spacing: 8) {
                                                Image(systemName: "sparkles")
                                                    .foregroundColor(.cyan)
                                                Text("Locking to screen in \(Int(ceil((1.0 - glance.glanceLockHoldProgress) * 3.0)))s...")
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
                                        }
                                        .padding(.horizontal, 4)
                                    }
                                    .padding(20)
                                }
                            } else if postureSubTab == 1 {
                                ScrollView {
                                    SpatialSoundstageRadarView()
                                        .padding(20)
                                }
                            } else {
                                ScrollView {
                                    BiometricTimelineScrubberView()
                                        .padding(20)
                                }
                            }
                        }
                        
                    // HUB 2: SLEEP & RECOVERY
                    case .sleepLab:
                        OvernightSleepRecoveryView()
                        
                    // HUB 3: FOCUS & MOBILITY
                    case .focusMobility:
                        VStack(spacing: 0) {
                            Picker("", selection: $focusSubTab) {
                                Text("2-Min Guided Stretches").tag(0)
                                Text("40Hz Focus Audio").tag(1)
                                Text("Resting Heart Rate & Vitals").tag(2)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 10)
                            
                            Divider()
                            
                            if focusSubTab == 0 {
                                StretchCoachView(motion: motion)
                            } else if focusSubTab == 1 {
                                ScrollView {
                                    OpenSourceUpgradesView()
                                        .padding(20)
                                }
                            } else {
                                ScrollView {
                                    BiohackingVitalityView()
                                        .padding(20)
                                }
                            }
                        }
                        
                    // HUB 4: SETTINGS & SHIELDS
                    case .settings:
                        VStack(spacing: 0) {
                            Picker("", selection: $settingsSubTab) {
                                Text("Shields & Energy").tag(0)
                                Text("Diagnostics & Audit").tag(1)
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, 24)
                            .padding(.top, 14)
                            .padding(.bottom, 10)
                            
                            Divider()
                            
                            if settingsSubTab == 0 {
                                SettingsView(motion: motion)
                            } else {
                                ScrollView {
                                    AuditAndLoopholesView()
                                        .padding(20)
                                }
                            }
                        }
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
        .frame(minWidth: 1020, minHeight: 680)
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
