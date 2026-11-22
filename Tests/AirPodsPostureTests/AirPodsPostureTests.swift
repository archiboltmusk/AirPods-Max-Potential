import Testing
import simd
@testable import AirPodsPosture
@testable import AirPodsCore

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
