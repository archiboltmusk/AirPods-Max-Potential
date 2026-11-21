import SwiftUI

public struct BiometricTimelineScrubberView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var hydration = HydrationTracker.shared
    @ObservedObject var typing = TypingFlowStateGatingManager.shared
    @State private var scrubProgress: Double = 0.85 // 0.0 to 1.0 (00:00 to 24:00)
    @State private var isScrubbing: Bool = false
    
    public init() {}
    
    private var scrubbedTimeLabel: String {
        let totalMinutes = Int(scrubProgress * 1440.0) // 24 * 60
        let hours = (totalMinutes / 60) % 24
        let minutes = totalMinutes % 60
        let ampm = hours >= 12 ? "PM" : "AM"
        let displayHour = hours == 0 ? 12 : (hours > 12 ? hours - 12 : hours)
        return String(format: "%d:%02d %@", displayHour, minutes, ampm)
    }
    
    private var scrubbedScore: Int {
        // Synthesize dynamic historical spline curve with high score during active upright periods
        let angle = scrubProgress * .pi * 6.0
        let wave = sin(angle) * 18.0 + cos(angle * 0.5) * 12.0
        return max(45, min(100, Int(82.0 + wave)))
    }
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("24-Hour Continuous Biometric Timeline")
                        .font(.headline)
                    Text("Apple Fitness-style high-resolution scrubbing across cervical ergonomics, breathing, and typing bursts.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Scrubbed Point Badge
                HStack(spacing: 8) {
                    Text(scrubbedTimeLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(.accentColor)
                    
                    Text("\(scrubbedScore)% Score")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(scrubbedScore > 80 ? .green : (scrubbedScore > 65 ? .orange : .red))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .appleGlass(cornerRadius: 12, opacity: 0.4)
            }
            
            // Continuous Spline Chart Canvas
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                
                ZStack(alignment: .leading) {
                    // Background grid lines (every 4 hours)
                    HStack(spacing: 0) {
                        ForEach(0..<6) { idx in
                            VStack {
                                Spacer()
                                Text(String(format: "%02d:00", idx * 4))
                                    .font(.system(size: 9))
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    // Gradient Fill Area
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: h - 20))
                        for i in 0...100 {
                            let x = (Double(i) / 100.0) * Double(w)
                            let progress = Double(i) / 100.0
                            let angle = progress * .pi * 6.0
                            let val = 82.0 + (sin(angle) * 18.0 + cos(angle * 0.5) * 12.0)
                            let normalized = (val - 40.0) / 60.0
                            let y = (h - 24) - (CGFloat(normalized) * (h - 40))
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                        path.addLine(to: CGPoint(x: w, y: h - 20))
                        path.closeSubpath()
                    }
                    .fill(
                        LinearGradient(
                            colors: [Color.cyan.opacity(0.35), Color.purple.opacity(0.15), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    
                    // Spline Stroke Line
                    Path { path in
                        for i in 0...100 {
                            let x = (Double(i) / 100.0) * Double(w)
                            let progress = Double(i) / 100.0
                            let angle = progress * .pi * 6.0
                            let val = 82.0 + (sin(angle) * 18.0 + cos(angle * 0.5) * 12.0)
                            let normalized = (val - 40.0) / 60.0
                            let y = (h - 24) - (CGFloat(normalized) * (h - 40))
                            if i == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .purple, .blue],
                            startPoint: .leading,
                            endPoint: .trailing
                        ),
                        lineWidth: 2.4
                    )
                    
                    // Event Dots (Hydration, Calibrations)
                    Group {
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: w * 0.28, y: h * 0.4)
                            .help("Hydration Sip Logged")
                        
                        Circle()
                            .fill(Color.blue)
                            .frame(width: 8, height: 8)
                            .position(x: w * 0.54, y: h * 0.35)
                            .help("Hydration Sip Logged")
                        
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .position(x: w * 0.12, y: h * 0.3)
                            .help("Zero-Touch Gravity Auto-Calibration Lock")
                    }
                    
                    // Interactive Scrubbing Needle
                    let scrubX = CGFloat(scrubProgress) * w
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 1.5, height: h - 16)
                        .position(x: scrubX, y: (h - 16) / 2)
                        .shadow(color: Color.white.opacity(0.8), radius: 4)
                    
                    Circle()
                        .fill(Color.white)
                        .frame(width: 10, height: 10)
                        .position(x: scrubX, y: 12)
                        .shadow(color: Color.black.opacity(0.3), radius: 2)
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            isScrubbing = true
                            let progress = max(0.0, min(1.0, Double(value.location.x / w)))
                            scrubProgress = progress
                        }
                        .onEnded { _ in
                            isScrubbing = false
                        }
                )
            }
            .frame(height: 140)
            .appleGlass(cornerRadius: 16, opacity: 0.3)
            
            // Timeline Legend Footer
            HStack(spacing: 20) {
                HStack(spacing: 6) {
                    Circle().fill(Color.cyan).frame(width: 6, height: 6)
                    Text("Cervical Alignment Spline").font(.caption2).foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.blue).frame(width: 6, height: 6)
                    Text("Hydration Sips (\(hydration.waterGlassesLogged) Logged)").font(.caption2).foregroundColor(.secondary)
                }
                HStack(spacing: 6) {
                    Circle().fill(Color.green).frame(width: 6, height: 6)
                    Text("Auto-Calibrations").font(.caption2).foregroundColor(.secondary)
                }
            }
        }
        .padding(18)
        .appleGlass(cornerRadius: 20, opacity: 0.4)
    }
}
