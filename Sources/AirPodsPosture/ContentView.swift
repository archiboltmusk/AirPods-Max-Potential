import SwiftUI

public struct ContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @State private var selectedTab: TabItem = .posture
    
    enum TabItem: String, CaseIterable, Identifiable {
        case posture = "Posture Monitor"
        case sensors = "AirPods Pro Sensors"
        case upgrades = "Power Upgrades"
        case advanced = "Spatial Intelligence"
        case elite = "Elite Labs"
        case ecosystem = "Ecosystem Bridges"
        case audit = "Loophole Audit"
        case stretches = "Neck Stretches"
        case potential = "AirPods Potential"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .posture: return "figure.walk.motion"
            case .sensors: return "earbuds.case.fill"
            case .upgrades: return "sparkles.square.filled.on.square"
            case .advanced: return "wand.and.stars.inverse"
            case .elite: return "crown.fill"
            case .ecosystem: return "applewatch.and.arrow.forward"
            case .audit: return "checkmark.shield"
            case .stretches: return "figure.mind.and.body"
            case .potential: return "sparkles"
            case .settings: return "gearshape"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        ZStack {
            // Metal Shader Live Fluid Chromatic Canvas
            FluidChromaticCanvasView(postureScore: motion.postureScore)
                .opacity(0.85)
            
            NavigationSplitView {
                List(TabItem.allCases, selection: $selectedTab) { tab in
                    NavigationLink(value: tab) {
                        Label(tab.rawValue, systemImage: tab.icon)
                    }
                }
                .navigationTitle("AirPodsIQ")
                .listStyle(.sidebar)
                
                // Sidebar Footer: Connection & Meeting indicator
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(motion.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(motion.isConnected ? (motion.isSimulated ? "Demo Simulation" : "AirPods Connected") : "Disconnected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if audioMonitor.isMicrophoneInUse {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.purple)
                                .font(.caption2)
                            Text("Mic Active (Call Guard)")
                                .font(.caption2.bold())
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            } detail: {
                Group {
                    switch selectedTab {
                    case .posture:
                        ScrollView {
                            VStack(spacing: 16) {
                                PostureVisualizerView(motion: motion)
                                
                                // Interactive 24-Hour Biomechanical Heatmap Scrub Bar
                                BiomechanicalHeatmapView()
                                
                                // Bottom Action Strip
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
                                    
                                    Button("Reset Stats") {
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
                            .padding(18)
                        }
                    case .sensors:
                        AirPodsProSensorsView()
                    case .upgrades:
                        UpgradesSuiteView()
                    case .advanced:
                        AdvancedUpgradesView()
                    case .elite:
                        EliteUpgradesView()
                    case .ecosystem:
                        EcosystemBridgesView()
                    case .audit:
                        AuditAndLoopholesView()
                    case .stretches:
                        StretchCoachView(motion: motion)
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
        .frame(minWidth: 800, minHeight: 580)
    }
}
