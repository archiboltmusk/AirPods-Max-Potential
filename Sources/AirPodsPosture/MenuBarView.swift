import SwiftUI

public struct MenuBarView: View {
    @ObservedObject var motion: MotionManager
    let openDashboard: () -> Void
    
    public init(motion: MotionManager, openDashboard: @escaping () -> Void) {
        self.motion = motion
        self.openDashboard = openDashboard
    }
    
    private var statusColor: Color {
        switch motion.postureState {
        case .optimal: return .green
        case .warning: return .orange
        case .slouching: return .red
        case .disconnected: return .gray
        }
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header status
            HStack {
                Image(systemName: motion.postureState.systemImage)
                    .foregroundColor(statusColor)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(motion.isConnected ? motion.postureState.rawValue : "No AirPods Detected")
                        .font(.headline)
                    Text(motion.isConnected ? "Deviations: Pitch \(Int(motion.deltaPitch))°, Roll \(Int(motion.deltaRoll))°" : "Connect AirPods Max or Pro")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Text("\(motion.postureScore)%")
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundColor(motion.postureScore > 80 ? .green : .orange)
            }
            .padding(.bottom, 4)
            
            Divider()
            
            // Quick Actions
            Button(action: {
                motion.calibrateCurrentPosture()
            }) {
                Label("Calibrate Neutral Upright", systemImage: "scope")
            }
            .disabled(!motion.isConnected)
            
            Button(action: {
                if motion.isTracking {
                    motion.stopTracking()
                } else {
                    motion.startTracking()
                }
            }) {
                Label(motion.isTracking ? "Pause Tracking" : "Resume Tracking", systemImage: motion.isTracking ? "pause.circle" : "play.circle")
            }
            
            Button(action: {
                motion.toggleSimulation()
            }) {
                Label(motion.isSimulated ? "Exit Demo Mode" : "Try Demo / Simulation Mode", systemImage: "wand.and.stars")
            }
            
            Divider()
            
            Button(action: {
                openDashboard()
            }) {
                Label("Open Full Dashboard...", systemImage: "macwindow")
            }
            
            Divider()
            
            Button(action: {
                NSApplication.shared.terminate(nil)
            }) {
                Label("Quit AirPods Posture", systemImage: "power")
            }
        }
        .padding(14)
        .frame(width: 270)
    }
}
