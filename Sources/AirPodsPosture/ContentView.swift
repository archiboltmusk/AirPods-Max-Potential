import SwiftUI
import AirPodsCore

/// AirPodsIQ: Complete Gold-Standard Architecture.
/// Organizes all 16 specialized hardware suites, clinical labs, ecosystem bridges,
/// and granular settings under 4 clean, structured categories.
public struct ContentView: View {
    let motion = MotionManager.shared
    let companion = FloatingMiniDeskCompanionManager.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var fitSentinel = AirPodsInsertionFitSentinel.shared
    
    @AppStorage("appVisualTheme") var appVisualTheme: String = "credStandard"
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
            // Adaptive Living Canvas: CRED Obsidian Noir vs Human Cinema vs Cupertino
            if appVisualTheme == "credStandard" {
                CREDPalette.canvasBg
                    .ignoresSafeArea()
            } else if appVisualTheme == "humanCinema" {
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
                    SidebarConnectionFooterView()
                }
                .navigationTitle("AirPodsIQ")
                .navigationSplitViewColumnWidth(min: 240, ideal: 270, max: 320)
            } detail: {
                Group {
                    switch selectedTab {
                    // SECTION 1: ESSENTIAL POSTURE & SLEEP
                    case .posture:
                        PostureTabContentView()
                    case .sleepLab:
                        OvernightSleepRecoveryView()
                    case .stretches:
                        StretchCoachView(motion: MotionManager.shared)
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
                            motion.calibrateCurrentPosture(force: true)
                        }) {
                            Image(systemName: "scope")
                        }
                        .disabled(!motion.isConnected)
                        .help("Calibrate neutral upright (⌘⇧C)")
                        
                        Button(action: {
                            AppDelegate.shared?.closeAllWindowsAndHideToMenuBar()
                        }) {
                            Image(systemName: "menubar.arrow.up.rectangle")
                        }
                        .help("Hide to Menu Bar (Exit Dock)")
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
        .sheet(isPresented: $fitSentinel.isFitGuidePresented) {
            AirPodsFitVerificationGuideView()
        }
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
