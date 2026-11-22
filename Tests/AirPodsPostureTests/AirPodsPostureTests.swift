import Foundation
import Testing
import simd
@testable import AirPodsPosture
@testable import AirPodsCore

@Suite(.serialized)
struct AirPodsPostureTests {
@Test func testPermanentPostureEngineProjection() async throws {
    let engine = await PermanentPostureEngine()
    
    // Test Upright Alignment: live gravity vector opposes upright vector
    // In our engine, up = -g_upright. So when upright, gLive = -up
    let profile = await engine.profiles[1]!
    let gUpright = -profile.up
    
    let result = await engine.evaluate(
        gravity: gUpright,
        rotRate: SIMD3<Double>(0, 0, 0),
        userAccel: SIMD3<Double>(0, 0, 0),
        sensorLocation: 1
    )
    
    #expect(result.isPermanent == true)
    #expect(abs(result.pitchDeg) < 0.01)
    #expect(abs(result.rollDeg) < 0.01)
}

@Test func testClampedAdaptationSlouchImmunity() async throws {
    let engine = await PermanentPostureEngine()
    
    // Simulate severe slouch (-20° pitch)
    let profile = await engine.profiles[1]!
    // Rotate gravity downward around profile.right by 20 degrees
    let angleRad = -20.0 * .pi / 180.0
    let slouchG = -profile.up * cos(angleRad) - profile.forward * sin(angleRad)
    
    let result = await engine.evaluate(
        gravity: slouchG,
        rotRate: SIMD3<Double>(0, 0, 0),
        userAccel: SIMD3<Double>(0, 0, 0),
        sensorLocation: 1
    )
    
    #expect(result.pitchDeg < -18.0)
    // Verify adaptation is completely locked out during slouch (cannot drift into slouch)
    let isAdapting = await engine.isAdaptingInsertionTolerance
    #expect(isAdapting == false)
}

@Test func testHeadGoingBackPitchPurity() async throws {
    let engine = await PermanentPostureEngine()
    let profile = await engine.profiles[1]!
    
    // Simulate tilting head backwards by 25 degrees (looking up at ceiling / cervical extension)
    let angleRad = 25.0 * .pi / 180.0
    let backwardG = -profile.up * cos(angleRad) + profile.forward * sin(angleRad)
    
    let result = await engine.evaluate(
        gravity: backwardG,
        rotRate: SIMD3<Double>(0, 0, 0),
        userAccel: SIMD3<Double>(0, 0, 0),
        sensorLocation: 1
    )
    
    // Pitch must be -25 degrees (negative = looking up/extension)
    #expect(abs(result.pitchDeg - (-25.0)) < 0.1)
    // Roll MUST BE EXACTLY 0.0° - ZERO cross-axis deflection to left or right!
    #expect(abs(result.rollDeg) < 0.01)
}

@Test func testSkullBasisOrthonormality() async throws {
    let engine = await PermanentPostureEngine()
    for (_, profile) in await engine.profiles {
        let dotUF = simd_dot(profile.up, profile.forward)
        let dotUR = simd_dot(profile.up, profile.right)
        let dotFR = simd_dot(profile.forward, profile.right)
        
        #expect(abs(dotUF) < 1e-4)
        #expect(abs(dotUR) < 1e-4)
        #expect(abs(dotFR) < 1e-4)
        #expect(abs(simd_length(profile.up) - 1.0) < 1e-4)
        #expect(abs(simd_length(profile.forward) - 1.0) < 1e-4)
        #expect(abs(simd_length(profile.right) - 1.0) < 1e-4)
    }
}

@Test func testInsertionSanityGateCrookedFit() async throws {
    let sentinel = await AirPodsInsertionFitSentinel()
    
    // Feed 65 frames of impossible anatomical resting roll (40° roll while stationary)
    for _ in 0..<65 {
        await sentinel.validateInsertionSanity(
            pitchDeg: 0.0,
            rollDeg: 40.0,
            rotRate: SIMD3<Double>(0, 0, 0),
            userAccel: SIMD3<Double>(0, 0, 0)
        )
    }
    
    let isCrooked = await sentinel.isCrookedFitDetected
    let isOptimal = await sentinel.isStemAngleOptimal
    #expect(isCrooked == true)
    #expect(isOptimal == false)
    
    // Now feed normal posture frames
    for _ in 0..<10 {
        await sentinel.validateInsertionSanity(
            pitchDeg: -4.0,
            rollDeg: 2.0,
            rotRate: SIMD3<Double>(0, 0, 0),
            userAccel: SIMD3<Double>(0, 0, 0)
        )
    }
    
    let clearedCrooked = await sentinel.isCrookedFitDetected
    let restoredOptimal = await sentinel.isStemAngleOptimal
    #expect(clearedCrooked == false)
    #expect(restoredOptimal == true)
}

@Test func testPostureFitGatekeeperTriGateValidation() async throws {
    let gatekeeper = await PostureFitGatekeeper()
    
    // 1. When audio is NOT routed to headphones (AirPods on desk / out of ear)
    await gatekeeper.setAudioRoutedForTesting(false)
    let profile = await PermanentPostureEngine.shared.profiles[1]!
    let gUpright = -profile.up
    
    await gatekeeper.evaluateDirect(
        gravity: gUpright,
        rotRate: SIMD3<Double>(0, 0, 0),
        userAccel: SIMD3<Double>(0, 0, 0),
        timestamp: 100.0,
        sensorLocationRaw: 1
    )
    
    var state = await gatekeeper.state
    var slouching = await gatekeeper.isSlouching
    #expect(state == .airPodsNotInEar)
    #expect(slouching == false)
    
    // 2. When audio route is connected, but earbud is seated crookedly (> 35° resting roll while stationary)
    await gatekeeper.setAudioRoutedForTesting(true)
    let crookedAngle = 42.0 * .pi / 180.0
    let crookedG = -profile.up * cos(crookedAngle) + profile.right * sin(crookedAngle)
    
    await gatekeeper.evaluateDirect(
        gravity: crookedG,
        rotRate: SIMD3<Double>(0, 0, 0),
        userAccel: SIMD3<Double>(0, 0, 0),
        timestamp: 100.02,
        sensorLocationRaw: 1
    )
    
    state = await gatekeeper.state
    slouching = await gatekeeper.isSlouching
    switch state {
    case .crookedInsertion:
        #expect(true)
    default:
        #expect(Bool(false), "Expected crookedInsertion state")
    }
    #expect(slouching == false)
    
    // 3. When in-ear and aligned (All 3 gates pass -> Ready)
    await gatekeeper.evaluateDirect(
        gravity: gUpright,
        rotRate: SIMD3<Double>(0, 0, 0),
        userAccel: SIMD3<Double>(0, 0, 0),
        timestamp: 100.04,
        sensorLocationRaw: 1
    )
    
    state = await gatekeeper.state
    #expect(state == .ready)
}

@Test func testGlanceAndLockAutoCalibrationWhenSittingStraight() async throws {
    let calibrator = await GlanceAndLockAutoCalibrator.shared
    let motion = await MotionManager.shared
    
    // Set an initial offset baseline
    await MainActor.run {
        motion.deltaPitch = 8.5
        motion.deltaRoll = -4.0
        calibrator.resetLock()
    }
    
    let uprightGravity = SIMD3<Double>(0.0, 0.0, -1.0)
    let currentQuat = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    
    // Evaluate when sitting upright and still
    await MainActor.run {
        calibrator.evaluate(
            currentQuat: currentQuat,
            gravity: uprightGravity,
            deltaPitch: 8.5,
            deltaRoll: -4.0,
            rotRate: 0.2,
            userEnergy: 0.005,
            isConnected: true
        )
        
        // Fast-forward hold duration by 2.5 seconds
        calibrator.setSteadyStartTimeForTesting(Date().addingTimeInterval(-2.5))
        
        calibrator.evaluate(
            currentQuat: currentQuat,
            gravity: uprightGravity,
            deltaPitch: 8.5,
            deltaRoll: -4.0,
            rotRate: 0.2,
            userEnergy: 0.005,
            isConnected: true
        )
    }
    
    let isCalibrated = await motion.isCalibrated
    let pitchAfter = await motion.deltaPitch
    let rollAfter = await motion.deltaRoll
    
    #expect(isCalibrated == true)
    #expect(abs(pitchAfter) < 0.01)
    #expect(abs(rollAfter) < 0.01)
}

@Test func testAutoCalibrationBlockedDuringSlouch() async throws {
    let calibrator = await GlanceAndLockAutoCalibrator.shared
    await MainActor.run {
        calibrator.resetLock()
    }
    
    // Slouching gravity: head down 20 degrees (gravity.y positive)
    let slouchG = SIMD3<Double>(0.0, 0.34, -0.94)
    let currentQuat = simd_quatd(ix: 0, iy: 0, iz: 0, r: 1)
    
    await MainActor.run {
        calibrator.evaluate(
            currentQuat: currentQuat,
            gravity: slouchG,
            deltaPitch: -20.0,
            deltaRoll: 0.0,
            rotRate: 0.1,
            userEnergy: 0.005,
            isConnected: true
        )
    }
    
    let progress = await calibrator.glanceLockHoldProgress
    #expect(progress == 0.0)
}

@Test func testAppNapPowerAssertionManagerSafetyAndZeroSystemSleepHold() async throws {
    let powerManager = await AppNapPowerAssertionManager.shared
    await MainActor.run {
        powerManager.acquireSleepTrackingAssertion(reason: "Unit Test Verification")
    }
    let isHeld = await powerManager.isAssertionHeld
    #expect(isHeld == true)
    
    await MainActor.run {
        powerManager.releaseAssertion()
    }
    let isReleased = await powerManager.isAssertionHeld
    #expect(isReleased == false)
}
}
