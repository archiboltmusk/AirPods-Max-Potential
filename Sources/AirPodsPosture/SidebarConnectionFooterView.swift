import SwiftUI

public struct SidebarConnectionFooterView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var audioMonitor = AudioEnvironmentMonitor.shared
    
    public init() {}
    
    public var body: some View {
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
}
