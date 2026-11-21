import Foundation
import simd

public struct EulerAngles: Equatable, Sendable {
    public var yaw: Double
    public var pitch: Double
    public var roll: Double
    
    public init(yaw: Double, pitch: Double, roll: Double) {
        self.yaw = yaw
        self.pitch = pitch
        self.roll = roll
    }
}

public enum QuaternionMath {
    @inline(__always)
    public static func clamp(_ v: Double, _ lo: Double = -1.0, _ hi: Double = 1.0) -> Double {
        min(hi, max(lo, v))
    }
    
    /// Decomposes a quaternion into Euler angles in degrees:
    /// Yaw: positive = look right, negative = look left
    /// Pitch: positive = look up, negative = look down (slouch)
    /// Roll: positive = tilt head right, negative = tilt head left
    public static func euler(from q: simd_quatd) -> EulerAngles {
        let w = q.real
        let x = q.imag.x
        let y = q.imag.y
        let z = q.imag.z
        
        let sinPitch = 2.0 * (y * z + w * x)
        let pitch = asin(clamp(sinPitch))
        let yaw = -atan2(2.0 * (w * z - x * y), 1.0 - 2.0 * (x * x + z * z))
        let roll = atan2(2.0 * (w * y - x * z), 1.0 - 2.0 * (x * x + y * y))
        
        let deg = 180.0 / .pi
        return EulerAngles(yaw: yaw * deg, pitch: pitch * deg, roll: roll * deg)
    }
    
    /// Computes the relative orientation of `current` with respect to `baseline`:
    /// qRel = normalize(qBaseline.inverse * current)
    public static func relativeOrientation(baseline: simd_quatd, current: simd_quatd) -> simd_quatd {
        return simd_normalize(baseline.inverse * current)
    }
}
