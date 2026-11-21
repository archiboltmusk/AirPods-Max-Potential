import AppKit

/// Procedural dynamic seated figure and spine curve drawn directly into the macOS menu bar.
/// Inspired by crafter-station/posture, dynamically bending with live pitch deviation.
public enum LiveSpineMenuBarGlyph {
    public enum Tone {
        case calm
        case alert
        case disconnected
    }

    public static func image(pitchDegrees: Double, tone: Tone, height: CGFloat = 18, label: String? = nil) -> NSImage {
        let scale = height / 18.0
        let textColor = color(for: tone)
        let textAttr: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 11 * scale, weight: .semibold),
            .foregroundColor: textColor
        ]
        let text = label.map { NSAttributedString(string: $0, attributes: textAttr) }
        let textWidth = text.map { ceil($0.size().width) + 4 * scale } ?? 0
        let size = NSSize(width: 18 * scale + textWidth, height: height)
        
        let image = NSImage(size: size, flipped: false) { _ in
            let col = color(for: tone)
            col.setStroke()
            col.setFill()
            
            // Draw seated figure (legs + bending spine)
            for path in figure(degrees: pitchDegrees, scale: scale) {
                path.stroke()
            }
            // Draw anatomical head pivot
            head(degrees: pitchDegrees, scale: scale).fill()
            
            if let text = text {
                let textY = (height - text.size().height) / 2.0
                text.draw(at: NSPoint(x: 18 * scale + 2 * scale, y: textY))
            }
            return true
        }
        
        image.isTemplate = (tone != .alert)
        return image
    }

    private static func color(for tone: Tone) -> NSColor {
        switch tone {
        case .calm:
            return .labelColor
        case .alert:
            return .systemOrange
        case .disconnected:
            return .secondaryLabelColor
        }
    }

    private static func bendRatio(_ degrees: Double) -> CGFloat {
        // Normalizes pitch drop (degrees < 0 is slouching down) into 0...1 bend ratio
        let absDegrees = max(0, -degrees)
        return CGFloat(min(max(absDegrees / 35.0, 0), 1.0))
    }

    private static func neckPoint(degrees: Double) -> CGPoint {
        let b = bendRatio(degrees)
        // Hip is at (5, 4.4); upright neck is at (5, 11.8).
        // As you slouch, the neck extends forward (X increases) and drops lower (Y decreases).
        return CGPoint(x: 5.0 + 3.8 * b, y: 11.8 - 2.2 * b)
    }

    private static func figure(degrees: Double, scale: CGFloat) -> [NSBezierPath] {
        let b = bendRatio(degrees)
        let hip = CGPoint(x: 5.0, y: 4.4)
        
        // Procedural Bézier spine
        let spine = NSBezierPath()
        spine.move(to: hip * scale)
        let cp1 = CGPoint(x: 4.8 - 1.6 * b, y: 7.2) * scale
        let cp2 = CGPoint(x: 4.9 - 0.7 * b, y: 10.2 - 0.5 * b) * scale
        spine.curve(to: neckPoint(degrees: degrees) * scale, controlPoint1: cp1, controlPoint2: cp2)

        // Seated ergonomic legs
        let legs = NSBezierPath()
        legs.move(to: hip * scale)
        legs.line(to: CGPoint(x: 12.0, y: 4.4) * scale)
        legs.line(to: CGPoint(x: 12.0, y: 0.8) * scale)

        return [spine, legs].map {
            $0.lineWidth = 1.85 * scale
            $0.lineCapStyle = .round
            $0.lineJoinStyle = .round
            return $0
        }
    }

    private static func head(degrees: Double, scale: CGFloat) -> NSBezierPath {
        // Head pitches down as degrees decreases
        let absDegrees = max(0, -degrees)
        let angle = (5.0 + min(absDegrees, 45.0) * 1.3) * .pi / 180.0
        let n = neckPoint(degrees: degrees)
        let center = CGPoint(x: n.x + 3.2 * sin(angle), y: n.y + 3.2 * cos(angle))
        let radius: CGFloat = 2.4
        
        return NSBezierPath(
            ovalIn: CGRect(
                x: (center.x - radius) * scale,
                y: (center.y - radius) * scale,
                width: 2.0 * radius * scale,
                height: 2.0 * radius * scale
            )
        )
    }
}

private func * (point: CGPoint, scale: CGFloat) -> CGPoint {
    CGPoint(x: point.x * scale, y: point.y * scale)
}
