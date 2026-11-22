import Foundation
import AVFoundation
import Vision
import Combine
import CoreMotion
import simd
import AppKit

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
    @Published public var faceTrackingConfidence: Double = 0.0 // 0.0 - 1.0
    @Published public var currentCameraName: String = "FaceTime HD Camera"
    @Published public var opticalFps: Int = 0
    @Published public var normalizedFaceBox: CGRect = .zero
    
    // Calibrated Posture Metrics (Deltas relative to Neutral Upright Baseline)
    @Published public var facePitch: Double = 0.0
    @Published public var faceRoll: Double = 0.0
    @Published public var faceYaw: Double = 0.0
    
    // Raw Angles Before Calibration
    @Published public var rawPitch: Double = 0.0
    @Published public var rawRoll: Double = 0.0
    @Published public var rawYaw: Double = 0.0
    
    // Calibration State (Just like Spatial Calibration!)
    @Published public var isCalibrated: Bool = false
    @Published public var baselinePitch: Double = 0.0
    @Published public var baselineRoll: Double = 0.0
    @Published public var baselineYaw: Double = 0.0
    @Published public var baselinePupilDistance: Double = 0.0
    @Published public var baselineFacialRatio: Double = 0.85
    @Published public var calibrationTimestamp: Date? = nil
    
    // Cranial Translation (Forward Head Craning / Turtle Neck in cm)
    @Published public var forwardCraningCm: Double = 0.0
    @Published public var craningSeverity: String = "Optimal Alignment"
    
    // Eye & Screen Fatigue (PERCLOS / Blink Monitoring)
    @Published public var blinkRateBPM: Int = 16
    @Published public var eyeAspectRatio: Double = 0.32
    @Published public var screenApneaAlert: String? = nil
    
    // Autonomous Fallback Configuration (Defaults to OFF: When in case, session is finished)
    @Published public var autoFallbackEnabled: Bool = false {
        didSet {
            UserDefaults.standard.set(autoFallbackEnabled, forKey: "autoOpticalFallbackEnabled")
        }
    }
    
    // Internal AVFoundation & Vision Stack
    nonisolated(unsafe) public let captureSession = AVCaptureSession()
    nonisolated(unsafe) private let videoOutput = AVCaptureVideoDataOutput()
    private let captureQueue = DispatchQueue(label: "com.airpodsiq.opticalsentinel", qos: .userInteractive)
    
    // Blink detection state
    private var blinkTimestamps: [Date] = []
    private var isEyeClosed: Bool = false
    private var lastBlinkDate: Date = Date()
    private var fpsCounter: Int = 0
    private var lastFpsTimestamp: Date = Date()
    private var stableFrameCount: Int = 0
    
    private var cancellables = Set<AnyCancellable>()
    
    private override init() {
        super.init()
        self.autoFallbackEnabled = UserDefaults.standard.object(forKey: "autoOpticalFallbackEnabled") as? Bool ?? false
        checkAuthorization()
        setupAirPodsHandoffListener()
    }
    
    // MARK: - Camera Permissions & Setup
    
    public func checkAuthorization() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            self.isCameraAuthorized = true
            setupCaptureSession()
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                Task { @MainActor in
                    self?.isCameraAuthorized = granted
                    if granted {
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
    
    public func setupCaptureSession() {
        guard isCameraAuthorized else { return }
        
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning { return }
            
            self.captureSession.beginConfiguration()
            self.captureSession.sessionPreset = .vga640x480
            
            // Remove existing inputs/outputs if re-configuring
            for input in self.captureSession.inputs {
                self.captureSession.removeInput(input)
            }
            for output in self.captureSession.outputs {
                self.captureSession.removeOutput(output)
            }
            
            // Discover best available camera (Front-facing, Continuity Camera, or default webcam)
            let discovery = AVCaptureDevice.DiscoverySession(
                deviceTypes: [
                    .builtInWideAngleCamera,
                    .external,
                    .continuityCamera
                ],
                mediaType: .video,
                position: .unspecified
            )
            
            let device = discovery.devices.first(where: { $0.position == .front })
                ?? discovery.devices.first(where: { !$0.isSuspended })
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
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self = self else { return }
                let motion = MotionManager.shared
                let airPodsActive = motion.isConnected && !motion.isSimulated && motion.activeDataSource.contains("AirPods")
                
                if airPodsActive {
                    // AirPods are active in-ear; sleep camera to save energy
                    if self.isRunning && !self.isManualSentinelActive {
                        self.stopSentinel()
                    }
                } else {
                    // AirPods are in case or disconnected; stop camera unless optical fallback explicitly enabled
                    if !self.autoFallbackEnabled {
                        if self.isRunning {
                            self.stopSentinel()
                        }
                    } else if !self.isRunning && self.isCameraAuthorized && HardwareClamshellSentinel.shared.isCameraPhysicallyAvailable {
                        self.startSentinel()
                    }
                }
            }
        }
    }
    
    public var isManualSentinelActive: Bool = false
    
    public func startSentinel(manual: Bool = false) {
        guard isCameraAuthorized && HardwareClamshellSentinel.shared.isCameraPhysicallyAvailable else { return }
        if manual { isManualSentinelActive = true }
        if self.captureSession.inputs.isEmpty {
            self.setupCaptureSession()
        }
        
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
        isManualSentinelActive = false
        guard isRunning else { return }
        captureQueue.async { [weak self] in
            guard let self = self else { return }
            if self.captureSession.isRunning {
                self.captureSession.stopRunning()
            }
            Task { @MainActor in
                self.isRunning = false
                self.faceDetected = false
                self.normalizedFaceBox = .zero
            }
        }
    }
    
    // MARK: - Spatial-Style Neutral Calibration
    
    /// Calibrates current head orientation as 0.0° neutral upright,
    /// storing baseline pitch, roll, yaw, pupillary distance, and facial proportion ratio.
    public func calibrateNeutralBaseline() {
        guard faceDetected else { return }
        
        baselinePitch = rawPitch
        baselineRoll = rawRoll
        baselineYaw = rawYaw
        baselinePupilDistance = currentPupilDistance
        baselineFacialRatio = currentFacialRatio
        isCalibrated = true
        calibrationTimestamp = Date()
        
        // Zero out current metrics immediately
        facePitch = 0.0
        faceRoll = 0.0
        faceYaw = 0.0
        forwardCraningCm = 0.0
        craningSeverity = "Optimal Alignment"
        
        NSSound(named: "Hero")?.play()
    }
    
    private var currentPupilDistance: Double = 0.0
    private var currentFacialRatio: Double = 0.85
    
    // MARK: - Vision Processing Loop (Apple Neural Engine)
    
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
                    self?.faceTrackingConfidence = 0.0
                }
                return
            }
            self.processFaceObservation(face)
        }
        
        request.revision = VNDetectFaceLandmarksRequestRevision3
        request.preferBackgroundProcessing = true
        
        let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
        try? handler.perform([request])
    }
    
    private nonisolated func processFaceObservation(_ face: VNFaceObservation) {
        guard let landmarks = face.landmarks else { return }
        
        var calculatedRoll: Double = 0.0
        var pupilDistance: Double = 0.0
        var calculatedPitch: Double = 0.0
        var calculatedYaw: Double = 0.0
        var facialRatio: Double = 0.85
        
        // 1. Roll & Pupillary Distance via Eye Pupils
        if let leftEye = landmarks.leftEye, let rightEye = landmarks.rightEye {
            let leftPoints = leftEye.normalizedPoints
            let rightPoints = rightEye.normalizedPoints
            
            if !leftPoints.isEmpty && !rightPoints.isEmpty {
                let lMid = leftPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                let lPupil = CGPoint(x: lMid.x / CGFloat(leftPoints.count), y: lMid.y / CGFloat(leftPoints.count))
                
                let rMid = rightPoints.reduce(CGPoint.zero) { CGPoint(x: $0.x + $1.x, y: $0.y + $1.y) }
                let rPupil = CGPoint(x: rMid.x / CGFloat(rightPoints.count), y: rMid.y / CGFloat(rightPoints.count))
                
                let dx = rPupil.x - lPupil.x
                let dy = rPupil.y - lPupil.y
                calculatedRoll = Double(atan2(dy, dx) * 180.0 / .pi)
                pupilDistance = Double(hypot(dx, dy))
                
                // 2. Scale-Invariant Vertical Facial Ratio for Pitch
                if let nose = landmarks.nose, let chin = landmarks.outerLips {
                    let nosePoints = nose.normalizedPoints
                    let chinPoints = chin.normalizedPoints
                    
                    if let noseTip = nosePoints.last, let chinCenter = chinPoints.first {
                        let eyeY = (lPupil.y + rPupil.y) * 0.5
                        let upperDist = abs(noseTip.y - eyeY)
                        let lowerDist = max(0.001, abs(chinCenter.y - noseTip.y))
                        
                        facialRatio = Double(upperDist / lowerDist)
                        
                        // Convert ratio to angular pitch deviation
                        // When looking down (slouch), nose moves down closer to chin: upperDist expands, lowerDist shrinks, ratio rises
                        let deltaRatio = facialRatio - 0.85
                        calculatedPitch = deltaRatio * 52.0
                    }
                    
                    // 3. Yaw via Nose Crest vs Eye Midpoint
                    if let noseCrest = nosePoints.first {
                        let eyeMidX = (lPupil.x + rPupil.x) * 0.5
                        let horizontalOffset = Double(noseCrest.x - eyeMidX)
                        calculatedYaw = horizontalOffset * 110.0
                    }
                }
            }
        }
        
        // 4. Eye Aspect Ratio (EAR) for Blinking & PERCLOS
        var currentEAR: Double = 0.32
        if let leftEye = landmarks.leftEye, leftEye.normalizedPoints.count >= 6 {
            let pts = leftEye.normalizedPoints
            let p1 = pts[0], p2 = pts[1], p3 = pts[2], p4 = pts[3], p5 = pts[4], p6 = pts[5]
            let num = hypot(p2.x - p6.x, p2.y - p6.y) + hypot(p3.x - p5.x, p3.y - p5.y)
            let den = 2.0 * hypot(p1.x - p4.x, p1.y - p4.y)
            currentEAR = Double(num / max(0.001, den))
        }
        
        // Extract Sendable primitives before crossing actor boundary
        let faceConfidence = Double(face.confidence)
        let faceBox = face.boundingBox
        
        // Dispatch to MainActor
        Task { @MainActor in
            self.faceDetected = true
            self.faceTrackingConfidence = faceConfidence
            self.normalizedFaceBox = faceBox
            self.currentPupilDistance = pupilDistance
            self.currentFacialRatio = facialRatio
            
            // Raw Angles
            self.rawPitch = calculatedPitch
            self.rawRoll = calculatedRoll
            self.rawYaw = calculatedYaw
            self.eyeAspectRatio = currentEAR
            
            // Auto-calibrate on first 30 frames if not yet calibrated
            if !self.isCalibrated {
                self.stableFrameCount += 1
                if self.stableFrameCount >= 25 {
                    self.calibrateNeutralBaseline()
                }
            }
            
            // Calibrated Angles (Just like Spatial Audio!)
            if self.isCalibrated {
                self.facePitch = self.rawPitch - self.baselinePitch
                self.faceRoll = self.rawRoll - self.baselineRoll
                self.faceYaw = self.rawYaw - self.baselineYaw
                
                // Forward Head Craning in cm
                let deltaD = max(0.0, pupilDistance - self.baselinePupilDistance)
                self.forwardCraningCm = deltaD * 85.0
                
                if self.forwardCraningCm > 6.0 {
                    self.craningSeverity = "Severe Turtle Neck (+6cm)"
                } else if self.forwardCraningCm > 3.0 {
                    self.craningSeverity = "Mild Forward Crane (+3cm)"
                } else {
                    self.craningSeverity = "Optimal Alignment"
                }
            } else {
                self.facePitch = self.rawPitch
                self.faceRoll = self.rawRoll
                self.faceYaw = self.rawYaw
            }
            
            // Update FPS
            self.fpsCounter += 1
            let now = Date()
            if now.timeIntervalSince(self.lastFpsTimestamp) >= 1.0 {
                self.opticalFps = self.fpsCounter
                self.fpsCounter = 0
                self.lastFpsTimestamp = now
            }
            
            // Blink monitoring
            if currentEAR < 0.20 && !self.isEyeClosed {
                self.isEyeClosed = true
                self.blinkTimestamps.append(now)
                self.lastBlinkDate = now
            } else if currentEAR >= 0.23 && self.isEyeClosed {
                self.isEyeClosed = false
            }
            
            self.blinkTimestamps.removeAll { now.timeIntervalSince($0) > 60.0 }
            self.blinkRateBPM = self.blinkTimestamps.count
            
            if now.timeIntervalSince(self.lastBlinkDate) > 12.0 {
                self.screenApneaAlert = "Dry Eye Warning: Extended Stare Detected"
            } else {
                self.screenApneaAlert = nil
            }
            
            // Stream into MotionManager when AirPods are docked in case
            let motion = MotionManager.shared
            if !motion.isConnected || motion.activeDataSource.contains("Optical") {
                let pRad = self.facePitch * .pi / 180.0
                let rRad = self.faceRoll * .pi / 180.0
                let yRad = self.faceYaw * .pi / 180.0
                
                let cr = cos(rRad * 0.5), sr = sin(rRad * 0.5)
                let cp = cos(pRad * 0.5), sp = sin(pRad * 0.5)
                let cy = cos(yRad * 0.5), sy = sin(yRad * 0.5)
                
                let qw = cr * cp * cy + sr * sp * sy
                let qx = sr * cp * cy - cr * sp * sy
                let qy = cr * sp * cy + sr * cp * sy
                let qz = cr * cp * sy - sr * cy * sp
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
