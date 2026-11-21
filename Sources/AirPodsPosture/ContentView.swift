import SwiftUI

public struct ContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @AppStorage("appVisualTheme") var appVisualTheme: String = "humanCinema"
    @State private var selectedTab: TabItem = .showcase
    
    // MARK: - Gold-Standard Apple HIG 4-Section Complete Architecture
    public enum TabItem: String, CaseIterable, Identifiable {
        // SECTION 1: EXPERIENCE & STUDIO
        case showcase = "Apple 360° Studio"
        case humanManifesto = "HUMAN.md Manifesto"
        
        // SECTION 2: BIOMETRICS & RADAR
        case posture = "Posture Monitor"
        case radar = "Spatial 360° Radar"
        case timeline = "Biometric Timeline"
        case stretches = "Neck Stretches & PT"
        
        // SECTION 3: LABS & INTELLIGENCE
        case openSourceLab = "Peer Open-Source Labs"
        case sensors = "AirPods Pro Sensors"
        case upgrades = "Power Upgrades"
        case advanced = "Spatial Intelligence"
        case elite = "Elite Labs"
        
        // SECTION 4: ECOSYSTEM & AUDIT
        case ecosystem = "Ecosystem Bridges"
        case audit = "Loophole & Tech Audit"
        case potential = "AirPods Potential Hub"
        case settings = "Settings & Appearance"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .showcase: return "headphones.circle.fill"
            case .humanManifesto: return "book.pages.fill"
            case .posture: return "figure.walk.motion"
            case .radar: return "dot.radiowaves.left.and.right"
            case .timeline: return "chart.xyaxis.line"
            case .stretches: return "figure.mind.and.body"
            case .openSourceLab: return "sparkles.rectangle.stack.fill"
            case .sensors: return "earbuds.case.fill"
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
            case .showcase: return .cyan
            case .humanManifesto: return HumanCinemaDesignSystem.Palette.vermilion
            case .posture: return .green
            case .radar: return .blue
            case .timeline: return .orange
            case .stretches: return .teal
            case .openSourceLab: return .purple
            case .sensors: return .indigo
            case .upgrades: return .yellow
            case .advanced: return .cyan
            case .elite: return .yellow
            case .ecosystem: return .green
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
                        // SECTION 1: EXPERIENCE & STUDIO
                        Section("EXPERIENCE & STUDIO") {
                            sidebarRow(.showcase)
                            sidebarRow(.humanManifesto)
                        }
                        
                        // SECTION 2: BIOMETRICS & RADAR
                        Section("BIOMETRICS & RADAR") {
                            sidebarRow(.posture)
                            sidebarRow(.radar)
                            sidebarRow(.timeline)
                            sidebarRow(.stretches)
                        }
                        
                        // SECTION 3: LABS & INTELLIGENCE
                        Section("LABS & INTELLIGENCE") {
                            sidebarRow(.openSourceLab)
                            sidebarRow(.sensors)
                            sidebarRow(.upgrades)
                            sidebarRow(.advanced)
                            sidebarRow(.elite)
                        }
                        
                        // SECTION 4: ECOSYSTEM & AUDIT
                        Section("ECOSYSTEM & AUDIT") {
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
                    // 1. STUDIO & MANIFESTO
                    case .showcase:
                        ScrollView {
                            Apple360HeroShowcaseView()
                                .padding(.vertical, 16)
                        }
                    case .humanManifesto:
                        HumanManifestoShowcaseView()
                        
                    // 2. BIOMETRICS & RADAR
                    case .posture:
                        ScrollView {
                            VStack(spacing: 20) {
                                PostureVisualizerView(motion: motion)
                                
                                // Interactive 24-Hour Biomechanical Heatmap Scrub Bar
                                BiomechanicalHeatmapView()
                                
                                // Interactive 24h Apple Fitness Spline Scrubber
                                BiometricTimelineScrubberView()
                                
                                // Slouch-Proof Calibration Interlock Alert
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
                                    .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.yellow.opacity(0.3), lineWidth: 1))
                                    .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                }
                                
                                // Bottom Consolidated Action Strip
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
                                    .help("Calibrate current neutral upright posture (⌘⇧C)")
                                    
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
                            }
                            .padding(20)
                        }
                    case .radar:
                        ScrollView {
                            SpatialSoundstageRadarView()
                                .padding(.vertical, 16)
                        }
                    case .timeline:
                        ScrollView {
                            BiometricTimelineScrubberView()
                                .padding(24)
                        }
                    case .stretches:
                        StretchCoachView(motion: motion)
                        
                    // 3. LABS & INTELLIGENCE
                    case .openSourceLab:
                        OpenSourceUpgradesView()
                    case .sensors:
                        AirPodsProSensorsView()
                    case .upgrades:
                        UpgradesSuiteView()
                    case .advanced:
                        AdvancedUpgradesView()
                    case .elite:
                        EliteUpgradesView()
                        
                    // 4. ECOSYSTEM & AUDIT
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
                    ToolbarItem(placement: .automatic) {
                        HStack(spacing: 10) {
                            if audioMonitor.isMicrophoneInUse {
                                HStack(spacing: 4) {
                                    Image(systemName: "mic.fill")
                                    Text("CALL ACTIVE")
                                }
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                            }
                            
                            if motion.isSimulated {
                                Text("SIMULATION ACTIVE")
                                    .font(.system(size: 10, weight: .bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.blue.opacity(0.15))
                                    .foregroundColor(.blue)
                                    .clipShape(Capsule())
                            }
                            
                            Button(action: {
                                motion.calibrateCurrentPosture()
                            }) {
                                Label("Calibrate", systemImage: "scope")
                            }
                            .help("Calibrate current head posture as neutral upright (⌘⇧C)")
                            .disabled(!motion.isConnected)
                        }
                    }
                }
            }
            
            // 20-20-20 Active Break Modal Overlay
            if breakTimer.isBreakActive {
                ZStack {
                    Color.black.opacity(0.65)
                        .ignoresSafeArea()
                    
                    VStack(spacing: 18) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        Text("20-20-20 Ergonomic Rest")
                            .font(.title.bold())
                        
                        Text("Look at an object at least 20 feet (6 meters) away.\nRoll your shoulders gently and take a deep breath.")
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
