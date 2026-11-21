import Foundation
import AppKit
import AVFoundation
import CoreGraphics

/// 1-Euro Adaptive Filter for IMU Jitter Elimination.
public final class OneEuroFilter {
    private var minCutoff: Double
    private var beta: Double
    private var dCutoff: Double
    private var xPrev: Double?
    private var dxPrev: Double = 0.0
    private var tPrev: Date?

    public init(minCutoff: Double = 1.0, beta: Double = 0.007, dCutoff: Double = 1.0) {
        self.minCutoff = minCutoff
        self.beta = beta
        self.dCutoff = dCutoff
    }

    private func alpha(rate: Double, cutoff: Double) -> Double {
        let tau = 1.0 / (2.0 * .pi * cutoff)
        let te = 1.0 / rate
        return 1.0 / (1.0 + tau / te)
    }

    public func filter(x: Double, timestamp: Date = Date()) -> Double {
        guard let tPrev = tPrev, let xPrev = xPrev else {
            self.xPrev = x
            self.tPrev = timestamp
            return x
        }

        let dt = max(1e-4, timestamp.timeIntervalSince(tPrev))
        let rate = 1.0 / dt
        let dx = (x - xPrev) * rate
        let aD = alpha(rate: rate, cutoff: dCutoff)
        let dxHat = aD * dx + (1.0 - aD) * dxPrev

        let cutoff = minCutoff + beta * abs(dxHat)
        let a = alpha(rate: rate, cutoff: cutoff)
        let xHat = a * x + (1.0 - a) * xPrev

        self.xPrev = xHat
        self.dxPrev = dxHat
        self.tPrev = timestamp
        return xHat
    }
}

/// 16-Gesture Cervical Action Runner.
/// Inspired by jaskirat1616/AirPoise: recognizes discrete head gestures and executes
/// Apple Shortcuts, media controls, and macOS shortcuts.
@MainActor
public final class HeadShortcutsActionRunner: ObservableObject {
    public static let shared = HeadShortcutsActionRunner()

    public enum GestureType: String, CaseIterable, Identifiable {
        case nodDown = "Single Nod"
        case doubleNod = "Double Nod"
        case shakeNo = "Single Shake"
        case doubleShake = "Double Shake"
        case lookLeft = "Look Left"
        case lookRight = "Look Right"
        case lookUp = "Look Up"
        case lookDown = "Look Down"
        case tiltLeft = "Tilt Left"
        case tiltRight = "Tilt Right"
        case tiltLeftHold = "Tilt Left & Hold"
        case tiltRightHold = "Tilt Right & Hold"
        case leanForward = "Lean Forward"
        case leanBack = "Lean Back"
        case rollHeadLeft = "Roll Head Left"
        case rollHeadRight = "Roll Head Right"

        public var id: String { rawValue }
    }

    public enum ActionTarget: String, CaseIterable, Identifiable {
        case none = "None"
        case playPauseMedia = "Media: Play / Pause"
        case nextTrack = "Media: Next Track"
        case previousTrack = "Media: Previous Track"
        case volumeUp = "Media: Volume Up"
        case volumeDown = "Media: Volume Down"
        case runAppleShortcut = "Run Apple Shortcut"
        case toggleMuteMic = "Toggle Mic Mute"
        case calibratePosture = "Calibrate Neutral Upright"
        case snoozeAlerts10m = "Snooze Alerts 10 Min"
        case speakCurrentPosture = "Voice Readout Posture"

        public var id: String { rawValue }
    }

    @Published public var isEnabled: Bool = true
    @Published public var lastDetectedGesture: String = "None"
    @Published public var lastExecutedAction: String = "Idle"
    @Published public var gestureMappings: [GestureType: ActionTarget] = [
        .doubleNod: .calibratePosture,
        .doubleShake: .snoozeAlerts10m,
        .tiltLeftHold: .previousTrack,
        .tiltRightHold: .nextTrack,
        .lookRight: .none,
        .lookLeft: .none
    ]
    @Published public var shortcutNames: [GestureType: String] = [:]

    private let pitchFilter = OneEuroFilter()
    private let rollFilter = OneEuroFilter()
    private let yawFilter = OneEuroFilter()

    private var lastGestureTime: Date = .distantPast
    private let speech = AVSpeechSynthesizer()

    // Peak velocity and threshold state for gesture recognition
    private var prevPitch: Double = 0
    private var prevRoll: Double = 0
    private var prevYaw: Double = 0
    private var nodCount: Int = 0
    private var shakeCount: Int = 0
    private var lastNodTime: Date = .distantPast
    private var lastShakeTime: Date = .distantPast

    private init() {}

    public func processMotion(pitch: Double, roll: Double, yaw: Double, userAccelY: Double = 0.0) {
        guard isEnabled else { return }

        // Walk-bounce rejection: suppress gestures during vertical locomotion steps
        if abs(userAccelY) > 0.45 {
            return
        }

        let fPitch = pitchFilter.filter(x: pitch)
        let fRoll = rollFilter.filter(x: roll)
        let fYaw = yawFilter.filter(x: yaw)

        let dPitch = fPitch - prevPitch
        let _ = fRoll - prevRoll
        let dYaw = fYaw - prevYaw

        prevPitch = fPitch
        prevRoll = fRoll
        prevYaw = fYaw

        let now = Date()
        guard now.timeIntervalSince(lastGestureTime) > 0.75 else { return }

        // 1. Double Nod / Single Nod Detection
        if dPitch < -9.0 && abs(fPitch) > 12.0 {
            if now.timeIntervalSince(lastNodTime) < 0.65 {
                triggerGesture(.doubleNod)
                lastNodTime = .distantPast
                return
            } else {
                lastNodTime = now
            }
        }

        // 2. Double Shake / Single Shake Detection
        if abs(dYaw) > 14.0 && abs(fYaw) > 16.0 {
            if now.timeIntervalSince(lastShakeTime) < 0.65 {
                triggerGesture(.doubleShake)
                lastShakeTime = .distantPast
                return
            } else {
                lastShakeTime = now
            }
        }

        // 3. Tilt Holds
        if fRoll < -24.0 {
            triggerGesture(.tiltLeftHold)
            return
        } else if fRoll > 24.0 {
            triggerGesture(.tiltRightHold)
            return
        }
    }

    public func triggerGesture(_ gesture: GestureType) {
        lastGestureTime = Date()
        lastDetectedGesture = gesture.rawValue
        SyntheticEarHapticEngine.shared.playTapticClick()

        let action = gestureMappings[gesture] ?? .none
        executeAction(action, for: gesture)
    }

    private func executeAction(_ action: ActionTarget, for gesture: GestureType) {
        lastExecutedAction = action.rawValue

        switch action {
        case .none:
            break
        case .playPauseMedia:
            dispatchMediaKey(keyCode: 16) // NX_KEYTYPE_PLAY
        case .nextTrack:
            dispatchMediaKey(keyCode: 19) // NX_KEYTYPE_NEXT
        case .previousTrack:
            dispatchMediaKey(keyCode: 20) // NX_KEYTYPE_PREVIOUS
        case .volumeUp:
            dispatchMediaKey(keyCode: 0)  // NX_KEYTYPE_SOUND_UP
        case .volumeDown:
            dispatchMediaKey(keyCode: 1)  // NX_KEYTYPE_SOUND_DOWN
        case .runAppleShortcut:
            if let name = shortcutNames[gesture], !name.isEmpty {
                let task = Process()
                task.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
                task.arguments = ["run", name]
                try? task.run()
            }
        case .toggleMuteMic:
            // Toggle system input mute
            let script = "set volume input volume (100 - (input volume of (get volume settings)))"
            var error: NSDictionary?
            NSAppleScript(source: script)?.executeAndReturnError(&error)
        case .calibratePosture:
            MotionManager.shared.calibrateCurrentPosture()
        case .snoozeAlerts10m:
            MotionManager.shared.snooze(minutes: 10)
        case .speakCurrentPosture:
            let pitch = Int(MotionManager.shared.deltaPitch)
            let utterance = AVSpeechUtterance(string: "Head pitch is \(abs(pitch)) degrees \(pitch < 0 ? "down" : "up").")
            utterance.rate = 0.52
            speech.speak(utterance)
        }
    }

    private func dispatchMediaKey(keyCode: Int32) {
        func postKey(down: Bool) {
            let flags = NSEvent.ModifierFlags(rawValue: down ? 0xa00 : 0xb00)
            let data1 = Int((keyCode << 16) | (down ? 0xa00 : 0xb00))
            let ev = NSEvent.otherEvent(
                with: .systemDefined,
                location: .zero,
                modifierFlags: flags,
                timestamp: 0,
                windowNumber: 0,
                context: nil,
                subtype: 8,
                data1: data1,
                data2: -1
            )
            ev?.cgEvent?.post(tap: .cghidEventTap)
        }
        postKey(down: true)
        postKey(down: false)
    }
}
