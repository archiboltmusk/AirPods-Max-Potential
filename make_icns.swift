import Cocoa

guard CommandLine.arguments.count > 2 else {
    print("Usage: swift make_icns.swift <input.png> <output.icns>")
    exit(1)
}

let inputPath = CommandLine.arguments[1]
let outputPath = CommandLine.arguments[2]

guard let inputImage = NSImage(contentsOfFile: inputPath) else {
    print("Error: Could not load image at \(inputPath)")
    exit(1)
}

// 1. Render 1024x1024 macOS Squircle Master
let masterSize = NSSize(width: 1024, height: 1024)
let masterRep = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: Int(masterSize.width),
    pixelsHigh: Int(masterSize.height),
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
)!

NSGraphicsContext.saveGraphicsState()
let context = NSGraphicsContext(bitmapImageRep: masterRep)!
NSGraphicsContext.current = context
context.imageInterpolation = .high

// Standard Apple macOS app icon grid:
// 1024x1024 canvas, 824x824 squircle centered (100px margins) with continuous 185px corner radius
let iconRect = NSRect(x: 100, y: 100, width: 824, height: 824)
let cornerRadius: CGFloat = 185.0
let squirclePath = NSBezierPath(roundedRect: iconRect, xRadius: cornerRadius, yRadius: cornerRadius)

// Add subtle drop shadow
let shadow = NSShadow()
shadow.shadowColor = NSColor.black.withAlphaComponent(0.40)
shadow.shadowOffset = NSSize(width: 0, height: -24)
shadow.shadowBlurRadius = 32

shadow.set()
NSColor.black.setFill()
squirclePath.fill()

// Draw the image clipped to squircle
NSGraphicsContext.saveGraphicsState()
squirclePath.addClip()
inputImage.draw(in: iconRect, from: NSRect(origin: .zero, size: inputImage.size), operation: .sourceOver, fraction: 1.0)

// Overlay subtle top-edge specular highlight (Apple Glass bevel)
let highlightGradient = NSGradient(
    startingColor: NSColor.white.withAlphaComponent(0.35),
    endingColor: NSColor.white.withAlphaComponent(0.0)
)!
highlightGradient.draw(in: NSRect(x: 100, y: 800, width: 824, height: 124), angle: -90)

// Subtle inner border (1.5pt crisp edge)
NSColor.white.withAlphaComponent(0.18).setStroke()
squirclePath.lineWidth = 3.0
squirclePath.stroke()

NSGraphicsContext.restoreGraphicsState()
NSGraphicsContext.restoreGraphicsState()

let finalMasterImage = NSImage(size: masterSize)
finalMasterImage.addRepresentation(masterRep)

// 2. Generate .iconset directory
let tempIconsetURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("AppIcon.iconset")
try? FileManager.default.removeItem(at: tempIconsetURL)
try! FileManager.default.createDirectory(at: tempIconsetURL, withIntermediateDirectories: true)

let sizes: [(String, Int, Int)] = [
    ("icon_16x16.png", 16, 1),
    ("icon_16x16@2x.png", 16, 2),
    ("icon_32x32.png", 32, 1),
    ("icon_32x32@2x.png", 32, 2),
    ("icon_128x128.png", 128, 1),
    ("icon_128x128@2x.png", 128, 2),
    ("icon_256x256.png", 256, 1),
    ("icon_256x256@2x.png", 256, 2),
    ("icon_512x512.png", 512, 1),
    ("icon_512x512@2x.png", 512, 2)
]

for (filename, points, scale) in sizes {
    let pixelSize = points * scale
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: pixelSize,
        pixelsHigh: pixelSize,
        bitsPerSample: 8,
        samplesPerPixel: 4,
        hasAlpha: true,
        isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0,
        bitsPerPixel: 0
    )!
    
    NSGraphicsContext.saveGraphicsState()
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.current = ctx
    ctx.imageInterpolation = .high
    
    finalMasterImage.draw(
        in: NSRect(x: 0, y: 0, width: pixelSize, height: pixelSize),
        from: NSRect(x: 0, y: 0, width: masterSize.width, height: masterSize.height),
        operation: .copy,
        fraction: 1.0
    )
    NSGraphicsContext.restoreGraphicsState()
    
    if let pngData = rep.representation(using: .png, properties: [:]) {
        let fileURL = tempIconsetURL.appendingPathComponent(filename)
        try! pngData.write(to: fileURL)
    }
}

// 3. Compile iconset into .icns using iconutil
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/bin/iconutil")
process.arguments = ["-c", "icns", tempIconsetURL.path, "-o", outputPath]
try! process.run()
process.waitUntilExit()

if process.terminationStatus == 0 {
    print("✅ Created AppIcon.icns successfully at: \(outputPath)")
} else {
    print("❌ iconutil failed with exit code: \(process.terminationStatus)")
    exit(process.terminationStatus)
}
