import Cocoa

let size = CGSize(width: 1024, height: 1024)
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil,
    width: Int(size.width),
    height: Int(size.height),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(1) }

ctx.interpolationQuality = .high

// 1. Standard Apple macOS Squircle: 824x824 centered with 100px margins
let squircleRect = CGRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185.0
let squirclePath = CGPath(roundedRect: squircleRect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)

// Drop shadow
ctx.saveGState()
ctx.setShadow(offset: CGSize(width: 0, height: -24), blur: 32, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.55))
ctx.addPath(squirclePath)
ctx.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1.0))
ctx.fillPath()
ctx.restoreGState()

// Clip to squircle
ctx.saveGState()
ctx.addPath(squirclePath)
ctx.clip()

// Deep Obsidian / Jet-Black Background with ultra-subtle radial gradient
let bgColors = [
    CGColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1.0),
    CGColor(red: 0.03, green: 0.03, blue: 0.04, alpha: 1.0)
] as CFArray
if let bgGradient = CGGradient(colorsSpace: colorSpace, colors: bgColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(
        bgGradient,
        startCenter: CGPoint(x: 512, y: 560),
        startRadius: 20,
        endCenter: CGPoint(x: 512, y: 512),
        endRadius: 550,
        options: [.drawsBeforeStartLocation, .drawsAfterEndLocation]
    )
}

// Subtle ambient glow in center
let glowColors = [
    CGColor(red: 0.0, green: 0.85, blue: 0.80, alpha: 0.14),
    CGColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.0)
] as CFArray
if let glowGradient = CGGradient(colorsSpace: colorSpace, colors: glowColors, locations: [0.0, 1.0]) {
    ctx.drawRadialGradient(
        glowGradient,
        startCenter: CGPoint(x: 512, y: 512),
        startRadius: 10,
        endCenter: CGPoint(x: 512, y: 512),
        endRadius: 320,
        options: [.drawsAfterEndLocation]
    )
}

// 2. Minimalist AirPods Headphone Arch
// Elegant 24pt thick continuous arc
let archCenter = CGPoint(x: 512, y: 540)
let archRadius: CGFloat = 220.0

ctx.saveGState()
let archPath = CGMutablePath()
archPath.addArc(center: archCenter, radius: archRadius, startAngle: .pi * 0.08, endAngle: .pi * 0.92, clockwise: false)

ctx.addPath(archPath)
ctx.setLineWidth(24)
ctx.setLineCap(.round)

// Gradient stroke for arch (Platinum white to soft electric cyan)
let strokeColors = [
    CGColor(red: 0.88, green: 0.92, blue: 0.98, alpha: 0.95),
    CGColor(red: 0.30, green: 0.85, blue: 0.92, alpha: 0.90)
] as CFArray
if let strokeGradient = CGGradient(colorsSpace: colorSpace, colors: strokeColors, locations: [0.0, 1.0]) {
    ctx.replacePathWithStrokedPath()
    ctx.clip()
    ctx.drawLinearGradient(
        strokeGradient,
        start: CGPoint(x: 512, y: 780),
        end: CGPoint(x: 512, y: 350),
        options: []
    )
}
ctx.restoreGState()

// 3. Minimalist Earcups (Sleek tilted rounded pills)
func drawMinimalEarcup(center: CGPoint, angleDegrees: CGFloat) {
    ctx.saveGState()
    ctx.translateBy(x: center.x, y: center.y)
    ctx.rotate(by: angleDegrees * .pi / 180.0)
    
    let cupRect = CGRect(x: -24, y: -65, width: 48, height: 130)
    let cupPath = CGPath(roundedRect: cupRect, cornerWidth: 24, cornerHeight: 24, transform: nil)
    
    // Ambient shadow
    ctx.setShadow(offset: CGSize(width: 0, height: -4), blur: 16, color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.6))
    
    // Earcup Fill (Titanium space grey with subtle edge rim)
    ctx.addPath(cupPath)
    ctx.setFillColor(CGColor(red: 0.16, green: 0.18, blue: 0.22, alpha: 1.0))
    ctx.fillPath()
    
    // Inner bevel rim
    ctx.addPath(cupPath)
    ctx.setStrokeColor(CGColor(red: 0.70, green: 0.82, blue: 0.95, alpha: 0.45))
    ctx.setLineWidth(2.5)
    ctx.strokePath()
    
    ctx.restoreGState()
}

// Left and Right earcups at the ends of the arch
let leftCupCenter = CGPoint(x: 512 - 205, y: 540 - 70)
let rightCupCenter = CGPoint(x: 512 + 205, y: 540 - 70)
drawMinimalEarcup(center: leftCupCenter, angleDegrees: 18)
drawMinimalEarcup(center: rightCupCenter, angleDegrees: -18)

// 4. Center Minimalist Vertebrae Posture Spine
// 6 clean, glowing rounded vertebrae capsules aligned vertically
let spineYs: [CGFloat] = [620, 565, 510, 455, 400, 345, 290]
let spineWidths: [CGFloat] = [36, 44, 52, 58, 54, 46, 36]

for i in 0..<spineYs.count {
    let y = spineYs[i]
    let w = spineWidths[i]
    let h: CGFloat = 16.0
    let rect = CGRect(x: 512 - (w / 2), y: y - (h / 2), width: w, height: h)
    let path = CGPath(roundedRect: rect, cornerWidth: h / 2, cornerHeight: h / 2, transform: nil)
    
    ctx.saveGState()
    // Neon Cyan & Emerald Spine Glow
    let glowColor = CGColor(red: 0.05, green: 0.92, blue: 0.75, alpha: 0.60)
    ctx.setShadow(offset: .zero, blur: 18, color: glowColor)
    
    ctx.addPath(path)
    ctx.setFillColor(CGColor(red: 0.10, green: 0.95, blue: 0.82, alpha: 0.95))
    ctx.fillPath()
    
    // Core white highlight in vertebrae center
    let innerRect = CGRect(x: 512 - ((w - 12) / 2), y: y - 2, width: w - 12, height: 4)
    let innerPath = CGPath(roundedRect: innerRect, cornerWidth: 2, cornerHeight: 2, transform: nil)
    ctx.addPath(innerPath)
    ctx.setFillColor(CGColor(red: 0.90, green: 1.0, blue: 0.98, alpha: 0.85))
    ctx.fillPath()
    
    ctx.restoreGState()
}

// 5. Crisp inner bevel border for the squircle
ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.16))
ctx.setLineWidth(3.0)
ctx.addPath(squirclePath)
ctx.strokePath()

ctx.restoreGState()

guard let img = ctx.makeImage() else { exit(1) }
let outURL = URL(fileURLWithPath: "/tmp/minimal_vector_icon.png")
let dest = CGImageDestinationCreateWithURL(outURL as CFURL, "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("Saved minimal vector icon to \(outURL.path)")
