import SwiftUI

public struct ContentView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    @ObservedObject var breakTimer = ErgonomicBreakTimer.shared
    @AppStorage("appVisualTheme") var appVisualTheme: String = "humanCinema"
    @State private var selectedTab: TabItem = .showcase
    
    // MARK: - Streamlined Apple HIG 4-Section Navigation
    public enum TabItem: String, CaseIterable, Identifiable {
        // Section 1: Studio & Manifesto
        case showcase = "Apple 360° Studio"
        case humanManifesto = "HUMAN.md Manifesto"
        
        // Section 2: Ergonomics & Health
        case posture = "Posture & Fatigue"
        case stretches = "Guided Mobility & PT"
        
        // Section 3: Innovations & Labs
        case openSourceLab = "Open-Source Labs"
        case sensors = "Sensors & Hardware"
        case featuresHub = "Advanced Features Hub"
        
        // Section 4: System
        case settings = "Settings & Appearance"
        
        public var id: String { rawValue }
        
        public var icon: String {
            switch self {
            case .showcase: return "headphones.circle.fill"
            case .humanManifesto: return "book.pages.fill"
            case .posture: return "figure.walk.motion"
            case .stretches: return "figure.mind.and.body"
            case .openSourceLab: return "sparkles.rectangle.stack.fill"
            case .sensors: return "earbuds.case.fill"
            case .featuresHub: return "wand.and.stars.inverse"
            case .settings: return "gearshape.fill"
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
                List(selection: $selectedTab) {
                    // SECTION 1: STUDIO & MANIFESTO
                    Section("STUDIO & MANIFESTO") {
                        NavigationLink(value: TabItem.showcase) {
                            Label(TabItem.showcase.rawValue, systemImage: TabItem.showcase.icon)
                        }
                        NavigationLink(value: TabItem.humanManifesto) {
                            Label(TabItem.humanManifesto.rawValue, systemImage: TabItem.humanManifesto.icon)
                        }
                    }
                    
                    // SECTION 2: ERGONOMICS & HEALTH
                    Section("ERGONOMICS & HEALTH") {
                        NavigationLink(value: TabItem.posture) {
                            Label(TabItem.posture.rawValue, systemImage: TabItem.posture.icon)
                        }
                        NavigationLink(value: TabItem.stretches) {
                            Label(TabItem.stretches.rawValue, systemImage: TabItem.stretches.icon)
                        }
                    }
                    
                    // SECTION 3: INNOVATIONS & LABS
                    Section("INNOVATIONS & LABS") {
                        NavigationLink(value: TabItem.openSourceLab) {
                            Label(TabItem.openSourceLab.rawValue, systemImage: TabItem.openSourceLab.icon)
                        }
                        NavigationLink(value: TabItem.sensors) {
                            Label(TabItem.sensors.rawValue, systemImage: TabItem.sensors.icon)
                        }
                        NavigationLink(value: TabItem.featuresHub) {
                            Label(TabItem.featuresHub.rawValue, systemImage: TabItem.featuresHub.icon)
                        }
                    }
                    
                    // SECTION 4: SYSTEM
                    Section("SYSTEM") {
                        NavigationLink(value: TabItem.settings) {
                            Label(TabItem.settings.rawValue, systemImage: TabItem.settings.icon)
                        }
                    }
                }
                .navigationTitle("AirPodsIQ")
                .listStyle(.sidebar)
                .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 280)
                
                // Sidebar Footer: Connection & Audio Status
                VStack(alignment: .leading, spacing: 6) {
                    Divider()
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(motion.isConnected ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                        Text(motion.isConnected ? (motion.isSimulated ? "Demo Simulation" : "AirPods Connected") : "Disconnected")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    
                    if audioMonitor.isMicrophoneInUse {
                        HStack(spacing: 6) {
                            Image(systemName: "mic.fill")
                                .foregroundColor(.purple)
                                .font(.caption2)
                            Text("Mic Active (Chimes Muted)")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.purple)
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.bottom, 10)
            } detail: {
                Group {
                    switch selectedTab {
                    case .showcase:
                        ScrollView {
                            Apple360HeroShowcaseView()
                                .padding(.vertical, 16)
                        }
                    case .humanManifesto:
                        HumanManifestoShowcaseView()
                        
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
                        
                    case .stretches:
                        StretchCoachView(motion: motion)
                        
                    case .openSourceLab:
                        OpenSourceUpgradesView()
                        
                    case .sensors:
                        AirPodsProSensorsView()
                        
                    case .featuresHub:
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
        .frame(minWidth: 920, minHeight: 640)
    }
}
