import SwiftUI
import SceneKit
import simd

public enum EarwearStyle: String, CaseIterable, Identifiable {
    case airPodsPro = "AirPods Pro"
    case airPodsMax = "AirPods Max"
    case pureBust = "Pure Sculpt"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .airPodsPro: return "earbuds"
        case .airPodsMax: return "headphones"
        case .pureBust: return "person.crop.circle"
        }
    }
}

public struct HumanFace3DView: NSViewRepresentable {
    public let pitch: Double
    public let roll: Double
    public let yaw: Double
    public let postureScore: Int
    public let earwearStyle: EarwearStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    
    public init(
        pitch: Double,
        roll: Double,
        yaw: Double,
        postureScore: Int,
        earwearStyle: EarwearStyle = .airPodsPro
    ) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.postureScore = postureScore
        self.earwearStyle = earwearStyle
    }
    
    public func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scene.background.contents = NSColor.clear
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        
        // 1. Camera Node (Apple Keynote Perspective, FOV 34° for refined portrait proportions)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 34
        cameraNode.position = SCNVector3(x: 0, y: 0.15, z: 5.8)
        scene.rootNode.addChildNode(cameraNode)
        scnView.pointOfView = cameraNode
        
        // 2. Cinematic Apple Keynote 3-Point Lighting Rig
        let keyLight = SCNNode()
        keyLight.name = "keyLightNode"
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1500
        keyLight.light?.color = NSColor(red: 1.0, green: 0.98, blue: 0.95, alpha: 1.0) // 5500K neutral studio key
        keyLight.position = SCNVector3(x: 3.2, y: 3.8, z: 5.2)
        scene.rootNode.addChildNode(keyLight)
        
        let rimLight = SCNNode()
        rimLight.name = "rimLightNode"
        rimLight.light = SCNLight()
        rimLight.light?.type = .omni
        rimLight.light?.intensity = 1100
        rimLight.light?.color = NSColor(red: 252.0/255.0, green: 65.0/255.0, blue: 9.0/255.0, alpha: 1.0) // HUMAN.md Vermilion Rim
        rimLight.position = SCNVector3(x: -3.8, y: 2.4, z: -3.2)
        scene.rootNode.addChildNode(rimLight)
        
        let coolFill = SCNNode()
        coolFill.light = SCNLight()
        coolFill.light?.type = .omni
        coolFill.light?.intensity = 420
        coolFill.light?.color = NSColor(red: 0.65, green: 0.82, blue: 1.0, alpha: 1.0) // Subtle cool studio fill
        coolFill.position = SCNVector3(x: 3.4, y: -1.2, z: -2.8)
        scene.rootNode.addChildNode(coolFill)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 440
        ambientLight.light?.color = NSColor(red: 0.35, green: 0.34, blue: 0.35, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        let headAssembly = SCNNode()
        headAssembly.name = "humanHeadAssembly"
        // Keep the rotational center near the base of the skull.
        headAssembly.pivot = SCNMatrix4MakeTranslation(0, -0.24, -0.10)
        headAssembly.position = SCNVector3(x: 0, y: -0.24, z: -0.10)

        if let bust = Self.makeBust() {
            headAssembly.addChildNode(bust)
        } else {
            let icon = SCNText(string: "3D model unavailable", extrusionDepth: 0)
            icon.font = NSFont.systemFont(ofSize: 12)
            icon.firstMaterial?.diffuse.contents = NSColor.white
            let label = SCNNode(geometry: icon)
            let (minimum, maximum) = label.boundingBox
            label.pivot = SCNMatrix4MakeTranslation((minimum.x + maximum.x) / 2, 0, 0)
            label.scale = SCNVector3(x: 0.02, y: 0.02, z: 0.02)
            scene.rootNode.addChildNode(label)
            return scnView
        }

        // --- AIRPODS PRO 2 RIG ---
        let airPodsProNode = SCNNode()
        airPodsProNode.name = "airPodsProRig"
        
        let podGlossMat = SCNMaterial()
        podGlossMat.lightingModel = .physicallyBased
        podGlossMat.diffuse.contents = NSColor(white: 0.98, alpha: 1.0)
        podGlossMat.metalness.contents = 0.12
        podGlossMat.roughness.contents = 0.08 // Apple gloss ceramic
        
        let siliconeTipMat = SCNMaterial()
        siliconeTipMat.lightingModel = .physicallyBased
        siliconeTipMat.diffuse.contents = NSColor(white: 0.90, alpha: 1.0)
        siliconeTipMat.roughness.contents = 0.72 // Soft matte silicone
        
        let acousticGrilleMat = SCNMaterial()
        acousticGrilleMat.lightingModel = .physicallyBased
        acousticGrilleMat.diffuse.contents = NSColor(white: 0.12, alpha: 1.0)
        acousticGrilleMat.metalness.contents = 0.6
        acousticGrilleMat.roughness.contents = 0.4
        
        func createAirPodPro(isLeft: Bool) -> SCNNode {
            let pod = SCNNode()
            
            // Acoustic bulb (rests in the concha bowl)
            let body = SCNNode(geometry: SCNSphere(radius: 0.065))
            body.geometry?.materials = [podGlossMat]
            pod.addChildNode(body)
            
            // Silicone ear tip (angled inward into ear canal)
            let tip = SCNNode(geometry: SCNCone(topRadius: 0.025, bottomRadius: 0.052, height: 0.055))
            tip.geometry?.materials = [siliconeTipMat]
            tip.position = SCNVector3(x: isLeft ? 0.045 : -0.045, y: 0.01, z: 0.01)
            tip.eulerAngles = SCNVector3(x: 0, y: 0, z: isLeft ? -.pi / 2.0 : .pi / 2.0)
            pod.addChildNode(tip)
            
            // Downward angled stem with mic port
            let stem = SCNNode(geometry: SCNCylinder(radius: 0.018, height: 0.18))
            stem.geometry?.materials = [podGlossMat]
            stem.position = SCNVector3(x: isLeft ? 0.01 : -0.01, y: -0.09, z: 0.025)
            stem.eulerAngles = SCNVector3(x: 0.32, y: 0, z: isLeft ? 0.12 : -0.12)
            pod.addChildNode(stem)
            
            // Acoustic black mesh vent on bulb
            let vent = SCNNode(geometry: SCNBox(width: 0.012, height: 0.035, length: 0.012, chamferRadius: 0.005))
            vent.geometry?.materials = [acousticGrilleMat]
            vent.position = SCNVector3(x: isLeft ? -0.05 : 0.05, y: 0.02, z: 0.0)
            pod.addChildNode(vent)
            
            return pod
        }
        
        let leftPro = createAirPodPro(isLeft: true)
        leftPro.position = SCNVector3(x: -0.485, y: 0.32, z: 0.05)
        leftPro.eulerAngles = SCNVector3(x: 0.26, y: -0.16, z: 0.18)
        airPodsProNode.addChildNode(leftPro)
        
        let rightPro = createAirPodPro(isLeft: false)
        rightPro.position = SCNVector3(x: 0.445, y: 0.32, z: 0.03)
        rightPro.eulerAngles = SCNVector3(x: 0.26, y: 0.16, z: -0.18)
        airPodsProNode.addChildNode(rightPro)
        
        headAssembly.addChildNode(airPodsProNode)
        
        // --- AIRPODS MAX RIG ---
        let airPodsMaxNode = SCNNode()
        airPodsMaxNode.name = "airPodsMaxRig"
        
        let aluminumCupMat = SCNMaterial()
        aluminumCupMat.lightingModel = .physicallyBased
        aluminumCupMat.diffuse.contents = NSColor(red: 0.84, green: 0.85, blue: 0.87, alpha: 1.0) // Space Silver / Gray Anodized
        aluminumCupMat.metalness.contents = 0.88
        aluminumCupMat.roughness.contents = 0.24
        
        let cushionMat = SCNMaterial()
        cushionMat.lightingModel = .physicallyBased
        cushionMat.diffuse.contents = NSColor(red: 0.26, green: 0.27, blue: 0.29, alpha: 1.0) // Magnetic knit fabric
        cushionMat.roughness.contents = 0.82
        cushionMat.metalness.contents = 0.05
        
        let headbandSteelMat = SCNMaterial()
        headbandSteelMat.lightingModel = .physicallyBased
        headbandSteelMat.diffuse.contents = NSColor(white: 0.92, alpha: 1.0)
        headbandSteelMat.metalness.contents = 0.95
        headbandSteelMat.roughness.contents = 0.14
        
        func createMaxCup(isLeft: Bool) -> SCNNode {
            let cup = SCNNode()
            
            // Outer anodized aluminum ear cup
            let shell = SCNNode(geometry: SCNBox(width: 0.073, height: 0.36, length: 0.28, chamferRadius: 0.036))
            shell.geometry?.materials = [aluminumCupMat]
            cup.addChildNode(shell)
            
            // Inner fabric cushion ring (facing ear concha)
            let cushion = SCNNode(geometry: SCNTorus(ringRadius: 0.105, pipeRadius: 0.024))
            cushion.geometry?.materials = [cushionMat]
            cushion.position = SCNVector3(x: isLeft ? 0.028 : -0.028, y: 0, z: 0)
            cushion.eulerAngles = SCNVector3(x: 0, y: 0, z: .pi / 2.0)
            cushion.scale = SCNVector3(x: 1.40, y: 1, z: 1.05)
            cup.addChildNode(cushion)
            
            // Telescopic stainless steel extension stem
            let arm = SCNNode(geometry: SCNCylinder(radius: 0.012, height: 0.18))
            arm.geometry?.materials = [headbandSteelMat]
            arm.position = SCNVector3(x: 0, y: 0.11, z: 0)
            cup.addChildNode(arm)
            
            return cup
        }
        
        let leftMaxCup = createMaxCup(isLeft: true)
        leftMaxCup.position = SCNVector3(x: -0.552, y: 0.35, z: 0.005)
        leftMaxCup.eulerAngles = SCNVector3(x: 0.12, y: 0.06, z: -0.08)
        airPodsMaxNode.addChildNode(leftMaxCup)
        
        let rightMaxCup = createMaxCup(isLeft: false)
        rightMaxCup.position = SCNVector3(x: 0.512, y: 0.35, z: -0.015)
        rightMaxCup.eulerAngles = SCNVector3(x: 0.12, y: -0.06, z: 0.08)
        airPodsMaxNode.addChildNode(rightMaxCup)
        
        // Build an open arch that follows the crown and ends at the ear cups.
        let bandSegments = 32
        for index in 0..<bandSegments {
            func point(at step: Int) -> SIMD3<Float> {
                let angle = Float(step) * .pi / Float(bandSegments)
                return SIMD3(-0.02 + 0.532 * cos(angle), 0.46 + 0.73 * sin(angle), -0.045)
            }
            let start = point(at: index)
            let end = point(at: index + 1)
            let segmentGeometry = SCNCapsule(capRadius: 0.023, height: CGFloat(simd_length(end - start)) + 0.046)
            segmentGeometry.firstMaterial = headbandSteelMat
            let segment = SCNNode(geometry: segmentGeometry)
            segment.simdPosition = (start + end) / 2
            segment.simdOrientation = simd_quatf(from: SIMD3(0, 1, 0), to: simd_normalize(end - start))
            airPodsMaxNode.addChildNode(segment)
        }

        headAssembly.addChildNode(airPodsMaxNode)
        
        // Configure initial earwear visibility
        airPodsProNode.isHidden = (earwearStyle != .airPodsPro)
        airPodsMaxNode.isHidden = (earwearStyle != .airPodsMax)
        
        scene.rootNode.addChildNode(headAssembly)
        return scnView
    }
    
    private static func makeBust() -> SCNNode? {
        // The signed app copies resources into Contents/Resources. SwiftPM uses its own bundle.
        guard let url = Bundle.main.url(forResource: "human_head", withExtension: "obj")
                ?? Bundle.module.url(forResource: "human_head", withExtension: "obj") else { return nil }

        guard let scene = try? SCNScene(url: url, options: nil) else { return nil }

        let ceramic = SCNMaterial()
        ceramic.lightingModel = .physicallyBased
        ceramic.diffuse.contents = NSColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1)
        ceramic.roughness.contents = 0.58
        ceramic.metalness.contents = 0.0
        ceramic.shaderModifiers = [.surface: facialDetailShader]

        let bust = SCNNode()
        for child in scene.rootNode.childNodes {
            bust.addChildNode(child)
        }
        var hasGeometry = false
        bust.enumerateChildNodes { node, _ in
            guard let geometry = node.geometry else { return }
            hasGeometry = true
            geometry.subdivisionLevel = 1
            geometry.materials = Array(repeating: ceramic, count: max(1, geometry.elementCount))
        }
        guard hasGeometry else { return nil }
        bust.scale = SCNVector3(x: 0.28, y: 0.28, z: 0.28)
        return bust
    }

    // Coordinates match the bundled sculpt before the view scales or rotates it.
    // Keep the tint in model space so it tracks the facial landmarks from every angle.
    private static let facialDetailShader = """
        #pragma body
        vec3 facePosition = (u_inverseModelTransform * u_inverseViewTransform
                             * vec4(_surface.position, 1.0)).xyz;
        float front = smoothstep(1.30, 1.90, facePosition.z);
        float centerX = facePosition.x + 0.08;
        float eyeX = abs(centerX) - 0.60;

        vec2 socket = vec2(eyeX / 0.40, (facePosition.y - 1.75) / 0.27);
        float socketTone = exp(-dot(socket, socket) * 1.5);
        float lidHeight = 1.73 - 0.52 * eyeX * eyeX;
        vec2 eyelid = vec2(eyeX / 0.30, (facePosition.y - lidHeight) / 0.055);
        float lidTone = exp(-dot(eyelid, eyelid) * 1.4);

        vec2 cheek = vec2((abs(centerX) - 0.83) / 0.40, (facePosition.y - 1.38) / 0.30);
        float cheekTone = exp(-dot(cheek, cheek) * 1.3);
        vec2 nose = vec2(centerX / 0.25, (facePosition.y - 1.08) / 0.22);
        float noseTone = exp(-dot(nose, nose) * 1.4);

        float lipHeight = 0.46 - 0.38 * centerX * centerX;
        vec2 lips = vec2(centerX / 0.41, (facePosition.y - lipHeight) / 0.14);
        float lipTone = exp(-dot(lips, lips) * 1.5);
        float lipCrease = exp(-pow(abs(facePosition.y - lipHeight - 0.02) / 0.032, 2.0))
                         * exp(-pow(abs(centerX) / 0.35, 4.0));

        vec3 warmTint = vec3(0.015, -0.049, -0.058) * (cheekTone + noseTone * 0.7)
                      + vec3(0.006, -0.095, -0.088) * lipTone;
        float creaseShade = socketTone * 0.032 + lidTone * 0.055 + lipCrease * 0.077;
        _surface.diffuse.rgb = clamp(_surface.diffuse.rgb + front * (warmTint - vec3(creaseShade)), 0.0, 1.0);
        """

    public func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene,
              let headAssembly = scene.rootNode.childNode(withName: "humanHeadAssembly", recursively: false) else { return }
        
        // 1. Instantaneous 60fps Apple Spatial Tracking (Zero Lag)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = reduceMotion ? 0 : 0.016
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        
        let pRad = CGFloat((pitch.isFinite ? pitch : 0) * .pi / 180.0)
        let rRad = CGFloat((roll.isFinite ? roll : 0) * .pi / 180.0)
        let yRad = CGFloat((yaw.isFinite ? yaw : 0) * .pi / 180.0)
        
        // Natural 1-to-1 Mirror Reflection Mode (like looking directly into a vanity mirror):
        // • Pitch: Tilting head back (looking up) tilts reflection up/back; slouching tilts down.
        // • Yaw: Turning right turns reflection to the right; turning left turns left.
        // • Roll: Tilting head to right shoulder tilts reflection right; left shoulder tilts left.
        headAssembly.eulerAngles = SCNVector3(x: pRad, y: yRad, z: -rRad)
        
        // 2. Earwear Visibility Sync
        if let proRig = headAssembly.childNode(withName: "airPodsProRig", recursively: false) {
            proRig.isHidden = (earwearStyle != .airPodsPro)
        }
        if let maxRig = headAssembly.childNode(withName: "airPodsMaxRig", recursively: false) {
            maxRig.isHidden = (earwearStyle != .airPodsMax)
        }
        
        // 3. Apple Keynote Studio Rim Lighting Shift (Subtle ambient feedback based on posture score)
        if let rim = scene.rootNode.childNode(withName: "rimLightNode", recursively: false)?.light {
            if postureScore >= 80 {
                // Optimal: Human Pulse Vermilion Rim
                rim.color = NSColor(red: 252.0/255.0, green: 65.0/255.0, blue: 9.0/255.0, alpha: 1.0)
                rim.intensity = 1100
            } else if postureScore >= 60 {
                // Warning: Gentle Warm Amber
                rim.color = NSColor(red: 255.0/255.0, green: 170.0/255.0, blue: 50.0/255.0, alpha: 1.0)
                rim.intensity = 1250
            } else {
                // Poor: Deep Crimson
                rim.color = NSColor(red: 240.0/255.0, green: 40.0/255.0, blue: 40.0/255.0, alpha: 1.0)
                rim.intensity = 1400
            }
        }
        
        SCNTransaction.commit()
    }
}
