import SwiftUI
import SceneKit

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
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = false
        
        // 1. Camera Node (Apple Keynote Perspective, FOV 34° for refined portrait proportions)
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 34
        cameraNode.position = SCNVector3(x: 0, y: 0.15, z: 7.2)
        scene.rootNode.addChildNode(cameraNode)
        
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
        
        // 3. Studio Ground Pedestal (Grounded Physical Pedestal, NOT a floating halo)
        let pedestalNode = SCNNode()
        pedestalNode.name = "pedestalNode"
        let discGeo = SCNCylinder(radius: 1.35, height: 0.03)
        let discMat = SCNMaterial()
        discMat.lightingModel = .physicallyBased
        discMat.diffuse.contents = NSColor(white: 0.15, alpha: 0.8)
        discMat.metalness.contents = 0.85
        discMat.roughness.contents = 0.25
        discGeo.materials = [discMat]
        pedestalNode.geometry = discGeo
        pedestalNode.position = SCNVector3(x: 0, y: -1.22, z: 0)
        scene.rootNode.addChildNode(pedestalNode)
        
        // 4. Human Head Assembly Root
        let headAssembly = SCNNode()
        headAssembly.name = "humanHeadAssembly"
        
        // Load the anatomically sculpted human head OBJ model
        var loadedMeshNode: SCNNode? = nil
        let bundleResourceURL = Bundle.main.url(forResource: "human_head", withExtension: "obj")
        let fallbackPath = "/Users/anupam/.gemini/antigravity/scratch/AirPodsMaxPotential/Sources/AirPodsPosture/Resources/human_head.obj"
        let fallbackURL = URL(fileURLWithPath: fallbackPath)
        let targetURL = bundleResourceURL ?? (FileManager.default.fileExists(atPath: fallbackPath) ? fallbackURL : nil)
        
        if let url = targetURL, let headScene = try? SCNScene(url: url, options: [.checkConsistency: false]) {
            let container = SCNNode()
            for child in headScene.rootNode.childNodes {
                container.addChildNode(child)
            }
            
            // Apply Studio Ceramic / Silicone Skin Shader
            container.enumerateHierarchy { (node, _) in
                if let geo = node.geometry {
                    let skinMat = SCNMaterial()
                    skinMat.lightingModel = .physicallyBased
                    skinMat.diffuse.contents = NSColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1.0)
                    skinMat.roughness.contents = 0.45
                    skinMat.metalness.contents = 0.08
                    geo.materials = [skinMat]
                }
            }
            
            // Normalize scale and center: scale = 0.28 places head span perfectly in viewport
            container.scale = SCNVector3(x: 0.28, y: 0.28, z: 0.28)
            container.position = SCNVector3(x: 0, y: 0, z: 0)
            loadedMeshNode = container
        }
        
        if let meshNode = loadedMeshNode {
            headAssembly.addChildNode(meshNode)
        } else {
            let fallbackHead = SCNNode(geometry: SCNSphere(radius: 1.0))
            fallbackHead.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.89, green: 0.86, blue: 0.82, alpha: 1.0)
            headAssembly.addChildNode(fallbackHead)
        }
        
        // 5. Build Earwear Nodes with Precision Anatomical Ear Alignment
        // Left ear concha center: X = -0.445, Y = 0.265, Z = 0.055
        // Right ear concha center: X = 0.405, Y = 0.265, Z = 0.055
        
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
        leftPro.position = SCNVector3(x: -0.445, y: 0.265, z: 0.055)
        leftPro.eulerAngles = SCNVector3(x: 0.26, y: -0.16, z: 0.18)
        airPodsProNode.addChildNode(leftPro)
        
        let rightPro = createAirPodPro(isLeft: false)
        rightPro.position = SCNVector3(x: 0.405, y: 0.265, z: 0.055)
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
            let shell = SCNNode(geometry: SCNCylinder(radius: 0.125, height: 0.055))
            shell.geometry?.materials = [aluminumCupMat]
            shell.eulerAngles = SCNVector3(x: 0, y: 0, z: .pi / 2.0)
            cup.addChildNode(shell)
            
            // Inner fabric cushion ring (facing ear concha)
            let cushion = SCNNode(geometry: SCNTorus(ringRadius: 0.105, pipeRadius: 0.024))
            cushion.geometry?.materials = [cushionMat]
            cushion.position = SCNVector3(x: isLeft ? 0.028 : -0.028, y: 0, z: 0)
            cushion.eulerAngles = SCNVector3(x: 0, y: 0, z: .pi / 2.0)
            cup.addChildNode(cushion)
            
            // Telescopic stainless steel extension stem
            let arm = SCNNode(geometry: SCNCylinder(radius: 0.012, height: 0.18))
            arm.geometry?.materials = [headbandSteelMat]
            arm.position = SCNVector3(x: 0, y: 0.11, z: 0)
            cup.addChildNode(arm)
            
            return cup
        }
        
        let leftMaxCup = createMaxCup(isLeft: true)
        leftMaxCup.position = SCNVector3(x: -0.475, y: 0.268, z: 0.02)
        leftMaxCup.eulerAngles = SCNVector3(x: 0.12, y: 0.06, z: -0.08)
        airPodsMaxNode.addChildNode(leftMaxCup)
        
        let rightMaxCup = createMaxCup(isLeft: false)
        rightMaxCup.position = SCNVector3(x: 0.435, y: 0.268, z: 0.02)
        rightMaxCup.eulerAngles = SCNVector3(x: 0.12, y: -0.06, z: 0.08)
        airPodsMaxNode.addChildNode(rightMaxCup)
        
        // Stainless steel arched canopy headband spanning over the skull crown (Y = 1.12)
        let archGeo = SCNTorus(ringRadius: 0.62, pipeRadius: 0.022)
        archGeo.materials = [headbandSteelMat]
        let archNode = SCNNode(geometry: archGeo)
        archNode.position = SCNVector3(x: -0.02, y: 0.68, z: 0.01)
        archNode.eulerAngles = SCNVector3(x: 0.10, y: 0, z: 0)
        archNode.scale = SCNVector3(x: 0.76, y: 0.74, z: 0.76)
        airPodsMaxNode.addChildNode(archNode)
        
        headAssembly.addChildNode(airPodsMaxNode)
        
        // Configure initial earwear visibility
        airPodsProNode.isHidden = (earwearStyle != .airPodsPro)
        airPodsMaxNode.isHidden = (earwearStyle != .airPodsMax)
        
        scene.rootNode.addChildNode(headAssembly)
        return scnView
    }
    
    public func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene,
              let headAssembly = scene.rootNode.childNode(withName: "humanHeadAssembly", recursively: false) else { return }
        
        // 1. Instantaneous 60fps Apple Spatial Tracking (Zero Lag)
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.016 // 16ms = 60Hz single-frame sync
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        
        let pRad = CGFloat(pitch * .pi / 180.0)
        let rRad = CGFloat(roll * .pi / 180.0)
        let yRad = CGFloat(yaw * .pi / 180.0)
        
        // Smoothly rotate anatomically faithful human bust with exact IMU attitude
        headAssembly.eulerAngles = SCNVector3(x: -pRad, y: yRad, z: -rRad)
        
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
