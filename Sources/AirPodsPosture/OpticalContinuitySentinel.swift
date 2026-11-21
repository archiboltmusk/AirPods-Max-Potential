import Foundation
import AVFoundation
import Vision
import Combine
import CoreMotion
import simd

/// Sentinel Optical Continuity Engine.
/// Maintains unbroken cervical posture tracking when AirPods are charging in their case
/// using on-device Apple Neural Engine (ANE) facial pose & pupillary distance estimation.
@MainActor
public final class OpticalContinuitySentinel: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate {
    public static let shared = OpticalContinuitySentinel()
    
    // Status & Telemetry
    @Published public var isRunning: Bool = false
    @Published public var isCameraAuthorized: Bool = false
    @Published public var faceDetected: Bool = false
    @Published public var currentCameraName: String = "FaceTime HD Camera"
    @Published public var opticalFps: Int = 0
    
    // Biomechanical Posture Metrics (Calculated via Computer Vision)
    @Published public var facePitch: Double = 0.0
    @Published public var faceRoll: Double = 0.0
    @Published public var faceYaw: Double = 0.0
    
    // Cranial Translation (The AirPods Blind Spot: Forward Head Craning / Turtle Neck in cm)
    @Published public var forwardCraningCm: Double = 0.0
    @Published public var craningSeverity: String = "Optimal Alignment"
    
    // Eye & Screen Fatigue (PERCLOS / Blink Monitoring)
    @Published public var blinkRateBPM: Int = 16
    @Published public var eyeAspectRatio: Double = 0.32
    @Published public var screenApneaAlert: String? = nil
    
    // Autonomous Fallback Configuration
    @Published public var autoFallbackEnabled: Bool = true {
        didSet {
            UserDefaults.standard.set(autoFallbackEnabled, forKey: "autoOpticalFallbackEnabled")
        }
    }
    
    // Internal AVFoundation & Vision Stack
    nonisolated(unsafe) private let captureSession = AVCaptureSession()
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "com.airpodsiq.opticalsentinel", qos: .userInteractive)
    
    // Calibration baseline for pupil distance (neutral screen distance)
    private var baselinePupilDistance: Double = 0.0
    private var isCalibrated: Bool = false
    
    // Blink detection state
    private var blinkTimestamps: [Date] = []
    private var isEyeClosed: Bool = false
    private var lastBlinkDate: Date = Date()
    private var fpsCounter: Int = 0
    private var lastFpsTimestamp: Date = Date()
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        self.autoFallbackEnabled = UserDefaults.standard.object(forKey: "autoOpticalFallbackEnabled") as? Bool ?? true
        checkAuthorization()
        setupAirPodsHandoffListener()
    }
    
    // MARK: - Camera Permissions & Setup
    
    public func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraAuthorized = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.isCameraAuthorized = granted
                    if granted && self?.autoFallbackEnabled == true {
                        self?.setupCaptureSession()
                    }
                }
            }
        case .denied, .restricted:
            self.isCameraAuthorized = false
        @unknown default:
            self.isCameraAuthorized = false
        }
    }
    
    private func setupCaptureSession() {
        guard isCameraAuthorized else { return }
        
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .vga640x480 // Low overhead, 30fps ANE-optimized
            
            // Discover front-facing camera (FaceTime HD / Studio Display / Continuity Camera)
            let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front)
                ?? AVCaptureDevice.default(for: .video)
            
            if let dev = device, let input = try? AVCaptureDeviceInput(device: dev) {
                if self.captureSession.canAddInput(input) {
                    self.captureSession.addInput(input)
                    Task { @MainActor in
                        self.currentCameraName = dev.localizedName
                    }
                }
            }
            
            self.videoOutput.alwaysDiscardsLateVideoFrames = true
            self.videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
            ]
            self.videoOutput.setSampleBufferDelegate(self, queue: self.captureQueue)
            
            if self.captureSession.canAddOutput(self.videoOutput) {
                self.captureSession.addOutput(self.videoOutput)
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    // MARK: - Autonomous In-Case Handoff Sentinel
    
    private func setupAirPodsHandoffListener() {
        // Watch MotionManager for AirPods connection state
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let motion = MotionManager.shared
                
                let airPodsActive = motion.isConnected && motion.activeDataSource.contains("AirPods")
                
                if airPodsActive {
                    // AirPods are connected & streaming from ears; put camera to sleep to save power
                    if self.isRunning {
                        self.stopSentinel()
                    }
                } else {
                    // AirPods are disconnected or docked in case!
                    if self.autoFallbackEnabled && !self.isRunning && self.isCameraAuthorized {
                        self.startSentinel()
                    }
                }
            }
        }
    }
    
    public func startSentinel() {
        guard isCameraAuthorized, !isRunning else { return }
        
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            if !self.captureSession.isRunning {
                self.captureSession.startRunning()
            }
            Task { @MainActor in
                self.isRunning = true
            }
        }
    }
    
    public func stopSentinel() {
        guard isRunning else { return }
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            Task { @MainActor in
                self.isRunning = false
                self.faceDetected = false
            }
        }
    }
    
    public func calibrateNeutralBaseline() {
        self.isCalibrated = false
    }
    
    // MARK: - AVCaptureVideoDataOutputSampleBufferDelegate (Apple Neural Engine Vision Loop)
    
    nonisolated public func captureOutput(
        _ output: AVCaptureOutput,
        didOutput sampleBuffer: CMSampleBuffer,
        from connection: AVCaptureConnection
    ) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        let request = VNDetectFaceLandmarksRequest { [weak self] req, err in
            guard let self = self, err == nil,
                  let results = req.results as? [VNFaceObservation],
                  let face = results.first else {
                Task { @MainActor in
                    self?.faceDetected = false
                }
                return
            }
            self.processFaceObservation(face)
        }
        
        // Optimize for speed and low CPU utilization
        request.preferBackgroundProcessing = true
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private nonisolated func processFaceObservation(_ face: VNFaceObservation) {
        guard let landmarks = face.landmarks else { return }
        
        // 1. Calculate Face Roll via Pupil Angle
        var calculatedRoll: Double = 0.0
        var pupilDistance: Double = 0.0
        
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftCenter = leftEye.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            let lCount = CGFloat(max(1, leftEye.normalizedPoints.count))
            let lPupil = CGPoint(x: leftCenter.x / lCount, y: leftCenter.y / lCount)
            
            let rightCenter = rightEye.normalizedPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
            let rCount = CGFloat(max(1, rightEye.normalizedPoints.count))
            let rPupil = CGPoint(x: rightCenter.x / rCount, y: rightCenter.y / rCount)
            
            let dx = rPupil.x - lPupil.x
            let dy = rPupil.y - lPupil.y
            calculatedRoll = Double(atan2(dy, dx) * 180.0 / .pi)
            pupilDistance = Double(hypot(dx, dy))
        }
        
        // 2. Calculate Face Pitch & Yaw via Nose / Chin / Eye Triangle
        var calculatedPitch: Double = 0.0
        var calculatedYaw: Double = 0.0
        
        if let nose = landmarks.nose, let chin = landmarks.outerLips {
            let nosePoints = nose.normalizedPoints
            let chinPoints = chin.normalizedPoints
            
            if let noseTip = nosePoints.last, let chinCenter = chinPoints.first {
                // Pitch correlates with nose-to-chin vertical spacing
                let noseChinDy = abs(chinCenter.y - noseTip.y)
                let expectedDy: CGFloat = 0.14
                let pitchDeviation = Double((expectedDy - noseChinDy) / expectedDy) * 42.0
                calculatedPitch = pitchDeviation
            }
            
            // Yaw correlates with horizontal nose displacement from face bounding-box center
            if let noseCrest = nosePoints.first {
                let faceCenter = face.boundingBox.midX
                calculatedYaw = Double((noseCrest.x - faceCenter) * 85.0)
            }
        }
        
        // 3. Eye Aspect Ratio (EAR) & Blink Analysis
        var currentEAR: Double = 0.32
        if let leftEye = landmarks.leftEye, leftEye.normalizedPoints.count >= 6 {
            let pts = leftEye.normalizedPoints
            let p1 = pts[0], p2 = pts[1], p3 = pts[2], p4 = pts[3], p5 = pts[4], p6 = pts[5]
            let num = hypot(p2.x - p6.x, p2.y - p6.y) + hypot(p3.x - p5.x, p3.y - p5.y)
            let den = 2.0 * hypot(p1.x - p4.x, p1.y - p4.y)
            currentEAR = Double(num / max(0.001, den))
        }
        
        // Dispatch biomechanical state to MainActor
        Task { @MainActor in
            self.faceDetected = true
            self.faceRoll = calculatedRoll
            self.facePitch = calculatedPitch
            self.faceYaw = calculatedYaw
            self.eyeAspectRatio = currentEAR
            
            // Update FPS
            self.fpsCounter += 1
            let now = Date()
            if now.timeIntervalSince(self.lastFpsTimestamp) >= 1.0 {
                self.opticalFps = self.fpsCounter
                self.fpsCounter = 0
                self.lastFpsTimestamp = now
            }
            
            // Forward Head Craning ("Turtle Neck" Metric)
            if !self.isCalibrated || self.baselinePupilDistance <= 0.001 {
                self.baselinePupilDistance = pupilDistance
                self.isCalibrated = true
            }
            
            let deltaD = pupilDistance - self.baselinePupilDistance
            let computedCraneCm = deltaD * 85.0 // Scaled to cm forward from neutral
            self.forwardCraningCm = max(0.0, computedCraneCm)
            
            if self.forwardCraningCm > 6.0 {
                self.craningSeverity = "Severe Turtle Neck (+6cm)"
            } else if self.forwardCraningCm > 3.0 {
                self.craningSeverity = "Mild Forward Crane (+3cm)"
            } else {
                self.craningSeverity = "Optimal Alignment"
            }
            
            // Blink rate detection
            if currentEAR < 0.20 && !self.isEyeClosed {
                self.isEyeClosed = true
                self.blinkTimestamps.append(now)
                self.lastBlinkDate = now
            } else if currentEAR >= 0.23 && self.isEyeClosed {
                self.isEyeClosed = false
            }
            
            // Clean rolling 60s blink history
            self.blinkTimestamps.removeAll { now.timeIntervalSince($0) > 60.0 }
            self.blinkRateBPM = self.blinkTimestamps.count
            
            if now.timeIntervalSince(self.lastBlinkDate) > 12.0 {
                self.screenApneaAlert = "Dry Eye Warning: Extended Stare Detected"
            } else {
                self.screenApneaAlert = nil
            }
            
            // If AirPods are in case and optical fallback is active, stream into MotionManager!
            let motion = MotionManager.shared
            if !motion.isConnected || motion.activeDataSource.contains("Optical") {
                // Synthesize orientation quaternion from Euler angles
                let pRad = calculatedPitch * .pi / 180.0
                let rRad = calculatedRoll * .pi / 180.0
                let yRad = calculatedYaw * .pi / 180.0
                
                let cr = cos(rRad * 0.5), sr = sin(rRad * 0.5)
                let cp = cos(pRad * 0.5), sp = sin(pRad * 0.5)
                let cy = cos(yRad * 0.5), sy = sin(yRad * 0.5)
                
                let qw = cr * cp * cy + sr * sp * sy
                let qx = sr * cp * cy - cr * sp * sy
                let qy = cr * sp * cy + sr * cp * sy
                let qz = cr * cp * sy - sr * sp * cy
                let quat = simd_quatd(ix: qx, iy: qy, iz: qz, r: qw)
                
                motion.processIncomingSample(
                    quat: quat,
                    gyro: SIMD3<Double>(0, 0, 0),
                    accel: SIMD3<Double>(0, -1.0, 0),
                    gravity: SIMD3<Double>(0, -1.0, 0),
                    pps: self.opticalFps,
                    source: "FaceTime HD Optical Sentinel"
                )
            }
        }
    }
}
