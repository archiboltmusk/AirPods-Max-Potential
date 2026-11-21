import SwiftUI

public struct ContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @State private var selectedTab: TabItem = .posture
    
    enum TabItem: String, CaseIterable, Identifiable {
        case posture = "Posture Monitor"
        case stretches = "Neck Stretches"
        case potential = "AirPods Potential"
        case settings = "Settings"
        
        var id: String { rawValue }
        
        var icon: String {
            switch self {
            case .posture: return "figure.walk.motion"
            case .stretches: return "figure.mind.and.body"
            case .potential: return "sparkles"
            case .settings: return "gearshape"
            }
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            List(TabItem.allCases, selection: $selectedTab) { tab in
                NavigationLink(value: tab) {
                    Label(tab.rawValue, systemImage: tab.icon)
                }
            }
            .navigationTitle("AirPodsIQ")
            .listStyle(.sidebar)
            
            // Sidebar Footer: Connection indicator
            VStack(alignment: .leading, spacing: 8) {
                Divider()
                HStack(spacing: 8) {
                    Circle()
                        .fill(motion.isConnected ? Color.green : Color.gray)
                        .frame(width: 8, height: 8)
                    Text(motion.isConnected ? (motion.isSimulated ? "Demo Simulation" : "AirPods Connected") : "Disconnected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 8)
            }
        } detail: {
            Group {
                switch selectedTab {
                case .posture:
                    ScrollView {
                        VStack(spacing: 20) {
                            PostureVisualizerView(motion: motion)
                            
                            // Bottom Action Strip
                            HStack(spacing: 16) {
                                Button(action: {
                                    motion.calibrateCurrentPosture()
                                }) {
                                    Label("Calibrate Neutral Upright", systemImage: "scope")
                                        .font(.headline)
                                        .padding(.vertical, 4)
                                }
                                .buttonStyle(.borderedProminent)
                                .disabled(!motion.isConnected)
                                
                                Button(action: {
                                    motion.toggleSimulation()
                                }) {
                                    Label(motion.isSimulated ? "Exit Demo" : "Try Demo Mode", systemImage: "wand.and.stars")
                                }
                                .buttonStyle(.bordered)
                                
                                Spacer()
                                
                                // Reset stats button
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
                        .padding(20)
                    }
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
                        if motion.isSimulated {
                            Text("SIMULATION ACTIVE")
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                        
                        Button(action: {
                            motion.calibrateCurrentPosture()
                        }) {
                            Label("Calibrate", systemImage: "scope")
                        }
                        .help("Calibrate current head posture as neutral upright")
                        .disabled(!motion.isConnected)
                    }
                }
            }
        }
        .frame(minWidth: 760, minHeight: 560)
    }
}
