import SwiftUI
import AirPodsCore

/// AirPodsPosture: Refined Gold Standard.
/// Pure, focused 3-tab layout: Posture, Daily Rhythm, and Settings.
public struct ContentView: View {
    let motion = MotionManager.shared
    let companion = FloatingMiniDeskCompanionManager.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @ObservedObject var fitSentinel = AirPodsInsertionFitSentinel.shared
    
    @AppStorage("appVisualTheme") var appVisualTheme: String = "credStandard"
    @State private var selectedTab: TabItem = .posture
    
    public enum TabItem: String, CaseIterable, Identifiable {
        case posture = "Posture Monitor"
        case rhythm = "Daily Rhythm & Mobility"
        case settings = "Settings & Hardware"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .posture: return "person.crop.artzone"
            case .rhythm: return "figure.mind.and.body"
            case .settings: return "gearshape.2.fill"
            }
        }
        
        public var iconColor: Color {
            switch self {
            case .posture: return CREDPalette.emeraldPlasma
            case .rhythm: return CREDPalette.electricCyan
            case .settings: return CREDPalette.champagneGold
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            CREDPalette.canvasBg
                .ignoresSafeArea()
            
            NavigationSplitView {
                VStack(spacing: 0) {
                    List(selection: $selectedTab) {
                        Section("AIRPODS POSTURE") {
                            sidebarRow(.posture)
                            sidebarRow(.rhythm)
                            sidebarRow(.settings)
                        }
                    }
                    .listStyle(.sidebar)
                    
                    Divider()
                        .opacity(0.4)
                    
                    // Sidebar Footer: Live Hardware Connection Indicator
                    SidebarConnectionFooterView()
                }
                .navigationTitle("AirPods Posture")
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
            } detail: {
                Group {
                    switch selectedTab {
                    case .posture:
                        PostureTabContentView()
                    case .rhythm:
                        DailyRhythmView()
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
                                .foregroundColor(companion.isCompanionVisible ? CREDPalette.emeraldPlasma : .secondary)
                        }
                        .help("Float Posture Buddy on Desktop")
                        
                        Button(action: {
                            _ = motion.calibrateCurrentPosture(force: true)
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
                        .ignoresSafeArea()
                    
                    VStack(spacing: 20) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 64))
                            .foregroundColor(CREDPalette.electricCyan)
                        
                        Text("20-20-20 Ergonomic Eye & Posture Reset")
                            .font(.title.bold())
                            .foregroundColor(CREDPalette.platinumWhite)
                        
                        Text("Look at an object 20 feet (6m) away for 20 seconds. Roll your shoulders and gently extend your cervical spine.")
                            .font(.body)
                            .foregroundColor(CREDPalette.phantomGray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 450)
                        
                        Text("\(Int(breakTimer.secondsRemaining))s")
                            .font(.system(size: 48, weight: .heavy, design: .monospaced))
                            .foregroundColor(CREDPalette.electricCyan)
                        
                        Button("Skip Break") {
                            breakTimer.completeBreak()
                        }
                        .buttonStyle(.bordered)
                        .tint(CREDPalette.electricCyan)
                    }
                    .padding(40)
                    .credCard(cornerRadius: 24, elevation: 20)
                }
                .transition(.opacity)
            }
        }
        .frame(minWidth: 1000, minHeight: 680)
        .sheet(isPresented: $fitSentinel.isFitGuidePresented) {
            AirPodsFitVerificationGuideView()
        }
    }
    
    @ViewBuilder
    private func sidebarRow(_ tab: TabItem) -> some View {
        NavigationLink(value: tab) {
            Label {
                Text(tab.rawValue)
                    .font(.system(size: 13, weight: .semibold))
            } icon: {
                Image(systemName: tab.icon)
                    .foregroundColor(tab.iconColor)
            }
        }
    }
}
