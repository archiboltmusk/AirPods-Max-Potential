import AppKit
import SwiftUI

@MainActor
public final class MenuBarSparklineRenderer: ObservableObject {
    public static let shared = MenuBarSparklineRenderer()
    
    @Published public var isEnabled: Bool = true
    @Published public var recentScores: [Int] = Array(repeating: 100, count: 24)
    @Published public var currentWaveformImage: NSImage? = nil
    
    private init() {}
    
    public func addSample(score: Int) {
        recentScores.append(score)
        if recentScores.count > 24 {
            recentScores.removeFirst()
        }
        
        currentWaveformImage = renderImage()
    }
    
    public func renderImage() -> NSImage {
        let size = NSSize(width: 32, height: 16)
        let img = NSImage(size: size, flipped: false) { rect in
            guard self.recentScores.count > 1 else { return true }
            
            let path = NSBezierPath()
            let stepX = rect.width / CGFloat(self.recentScores.count - 1)
            
            for (idx, sc) in self.recentScores.enumerated() {
                let x = CGFloat(idx) * stepX
                // Map score 0-100 to y 2-14
                let norm = CGFloat(sc) / 100.0
                let y = 2.0 + (norm * 12.0)
                
                if idx == 0 {
                    path.move(to: NSPoint(x: x, y: y))
                } else {
                    path.line(to: NSPoint(x: x, y: y))
                }
            }
            
            let avgScore = self.recentScores.reduce(0, +) / self.recentScores.count
            let color: NSColor = avgScore > 80 ? .systemGreen : (avgScore > 60 ? .systemOrange : .systemRed)
            color.setStroke()
            path.lineWidth = 1.6
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            path.stroke()
            
            return true
        }
        
        img.isTemplate = false
        return img
    }
}
