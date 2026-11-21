import SwiftUI
import AVFoundation
import AppKit

/// Live Camera Preview View with Biometric Face Tracking Overlay & Spatial Calibration.
public struct OpticalCameraPreviewView: View {
    @ObservedObject var sentinel = OpticalContinuitySentinel.shared
    @State private var showPreview: Bool = true
    
    public init() {}
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header bar
            HStack(spacing: 10) {
                Image(systemName: "camera.viewfinder")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.teal)
                    .frame(width: 32, height: 32)
                    .background(Color.teal.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Optical Face Sentinel & Spatial Calibration")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Real-time Apple Neural Engine facial tracking & calibrated neutral baseline")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Status Pill
                HStack(spacing: 6) {
                    Circle()
                        .fill(sentinel.faceDetected ? Color.green : Color.orange)
                        .frame(width: 8, height: 8)
                    Text(sentinel.faceDetected ? "Face Locked (\(sentinel.opticalFps) FPS)" : (sentinel.isRunning ? "Acquiring Face..." : "Camera Sleeping"))
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(sentinel.faceDetected ? .green : .orange)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.primary.opacity(0.06))
                .clipShape(Capsule())
            }
            
            // Viewport
            ZStack {
                // Background Box
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.85))
                    .frame(height: 220)
                
                if sentinel.isRunning && showPreview {
                    // Live AVFoundation Preview Layer
                    CameraFeedRepresentable(session: sentinel.captureSession)
                        .frame(height: 220)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                        .opacity(0.9)
                    
                    // Vision HUD Overlay
                    GeometryReader { geo in
                        ZStack {
                            if sentinel.faceDetected && sentinel.normalizedFaceBox != .zero {
                                // Face Bounding Box
                                let box = sentinel.normalizedFaceBox
                                let rect = CGRect(
                                    x: (1.0 - box.maxX) * geo.size.width, // Mirrored for webcam
                                    y: (1.0 - box.maxY) * geo.size.height,
                                    width: box.width * geo.size.width,
                                    height: box.height * geo.size.height
                                )
                                
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(Color.green.opacity(0.85), lineWidth: 2)
                                    .frame(width: max(20, rect.width), height: max(20, rect.height))
                                    .position(x: rect.midX, y: rect.midY)
                                    .shadow(color: .green.opacity(0.5), radius: 6)
                                
                                // Center Reticle
                                Circle()
                                    .fill(Color.green)
                                    .frame(width: 6, height: 6)
                                    .position(x: rect.midX, y: rect.midY)
                            }
                        }
                    }
                    .frame(height: 220)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: sentinel.isRunning ? "eye.slash.fill" : "camera.fill")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary)
                        Text(sentinel.isRunning ? "Camera Preview Hidden (Privacy Shutter)" : "Camera is on Standby (Runs when AirPods are charging)")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    .frame(height: 220)
                }
                
                // Real-time Angle Badges (Bottom HUD)
                VStack {
                    Spacer()
                    HStack(spacing: 12) {
                        HUDMetricPill(label: "Pitch", value: String(format: "%+.1f°", sentinel.facePitch), color: abs(sentinel.facePitch) > 10 ? .orange : .green)
                        HUDMetricPill(label: "Roll", value: String(format: "%+.1f°", sentinel.faceRoll), color: abs(sentinel.faceRoll) > 8 ? .orange : .green)
                        HUDMetricPill(label: "Yaw", value: String(format: "%+.1f°", sentinel.faceYaw), color: abs(sentinel.faceYaw) > 15 ? .orange : .green)
                        HUDMetricPill(label: "Crane", value: String(format: "+%.1f cm", sentinel.forwardCraningCm), color: sentinel.forwardCraningCm > 4 ? .red : .teal)
                    }
                    .padding(8)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    .padding(.bottom, 10)
                }
            }
            .frame(height: 220)
            
            // Bottom Action Controls
            HStack(spacing: 12) {
                // Calibrate Button
                Button(action: {
                    sentinel.calibrateNeutralBaseline()
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "scope")
                        Text(sentinel.isCalibrated ? "Recalibrate Neutral Face" : "Calibrate Neutral Face")
                    }
                    .font(.system(size: 12, weight: .semibold))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
                .disabled(!sentinel.faceDetected)
                .help("Saves your current upright head position as 0.0° neutral baseline")
                
                // Start / Stop Camera Button
                Button(action: {
                    if sentinel.isRunning {
                        sentinel.stopSentinel()
                    } else {
                        sentinel.startSentinel(manual: true)
                    }
                }) {
                    HStack(spacing: 5) {
                        Image(systemName: sentinel.isRunning ? "stop.fill" : "play.fill")
                        Text(sentinel.isRunning ? "Stop Camera" : "Start Webcam Sentinel")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                // Privacy Shutter Toggle
                Button(action: {
                    showPreview.toggle()
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: showPreview ? "eye.slash" : "eye")
                        Text(showPreview ? "Hide Feed" : "Show Feed")
                    }
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                if sentinel.isCalibrated {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("Calibrated to Screen Baseline")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appleGlass(cornerRadius: 16, opacity: 0.35)
    }
}

struct HUDMetricPill: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 11, weight: .heavy, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

// MARK: - AppKit Video Feed Representable

struct CameraFeedRepresentable: NSViewRepresentable {
    let session: AVCaptureSession
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
        
        let previewLayer = AVCaptureVideoPreviewLayer(session: session)
        previewLayer.videoGravity = .resizeAspectFill
        previewLayer.autoresizingMask = [.layerWidthSizable, .layerHeightSizable]
        
        // Mirror horizontally so webcam acts like a mirror
        if let connection = previewLayer.connection, connection.isVideoMirroringSupported {
            connection.automaticallyAdjustsVideoMirroring = false
            connection.isVideoMirrored = true
        }
        
        view.layer?.addSublayer(previewLayer)
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        if let previewLayer = nsView.layer?.sublayers?.first as? AVCaptureVideoPreviewLayer {
            previewLayer.frame = nsView.bounds
        }
    }
}
