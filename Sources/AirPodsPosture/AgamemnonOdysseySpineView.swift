import SwiftUI
import SceneKit

public struct AgamemnonOdysseySpineView: NSViewRepresentable {
    public let pitch: Double
    public let roll: Double
    public let yaw: Double
    public let postureScore: Int
    
    public init(pitch: Double, roll: Double, yaw: Double, postureScore: Int) {
        self.pitch = pitch
        self.roll = roll
        self.yaw = yaw
        self.postureScore = postureScore
    }
    
    public func makeNSView(context: Context) -> SCNView {
        let scnView = SCNView()
        let scene = SCNScene()
        scnView.scene = scene
        scnView.backgroundColor = .clear
        scnView.antialiasingMode = .multisampling4X
        scnView.autoenablesDefaultLighting = false
        scnView.allowsCameraControl = true
        
        // 1. Camera Node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 44
        cameraNode.position = SCNVector3(x: 0, y: 0.8, z: 8.5)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Mythological Cinematic Lighting (Gold Key, Obsidian Rim, Divine Aura)
        let goldSunLight = SCNNode()
        goldSunLight.light = SCNLight()
        goldSunLight.light?.type = .omni
        goldSunLight.light?.intensity = 1800
        goldSunLight.light?.color = NSColor(red: 1.0, green: 0.82, blue: 0.35, alpha: 1.0)
        goldSunLight.position = SCNVector3(x: 4.5, y: 5.5, z: 6.0)
        scene.rootNode.addChildNode(goldSunLight)
        
        let titanRimLight = SCNNode()
        titanRimLight.light = SCNLight()
        titanRimLight.light?.type = .omni
        titanRimLight.light?.intensity = 1400
        titanRimLight.light?.color = NSColor(red: 0.95, green: 0.25, blue: 0.45, alpha: 1.0)
        titanRimLight.position = SCNVector3(x: -5.0, y: 2.0, z: -4.0)
        scene.rootNode.addChildNode(titanRimLight)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 350
        ambientLight.light?.color = NSColor(white: 0.3, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // 3. Agamemnon Odyssey Spine Assembly Root
        let spineAssembly = SCNNode()
        spineAssembly.name = "agamemnonSpineAssembly"
        
        let totalSegments = 8
        for i in 0..<totalSegments {
            let segNode = SCNNode()
            segNode.name = "odyssey_vertebra_\(i)"
            
            let radius: CGFloat = 0.52 - CGFloat(i) * 0.02
            let height: CGFloat = 0.32
            
            let cylinderGeo = SCNCylinder(radius: radius, height: height)
            cylinderGeo.radialSegmentCount = 36
            cylinderGeo.firstMaterial?.lightingModel = .physicallyBased
            cylinderGeo.firstMaterial?.diffuse.contents = NSColor(red: 0.88, green: 0.72, blue: 0.28, alpha: 1.0)
            cylinderGeo.firstMaterial?.metalness.contents = 0.92
            cylinderGeo.firstMaterial?.roughness.contents = 0.22
            
            let coreNode = SCNNode(geometry: cylinderGeo)
            
            // Iliad Transverse Flanges (Spinal Wings)
            let wingLeft = SCNNode(geometry: SCNCone(topRadius: 0.04, bottomRadius: 0.16, height: 0.65))
            wingLeft.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
            let wingOffset: CGFloat = radius + 0.28
            wingLeft.position = SCNVector3(x: -wingOffset, y: 0, z: 0)
            wingLeft.eulerAngles = SCNVector3(x: 0, y: 0, z: CGFloat.pi / 2.0)
            coreNode.addChildNode(wingLeft)
            
            let wingRight = SCNNode(geometry: SCNCone(topRadius: 0.04, bottomRadius: 0.16, height: 0.65))
            wingRight.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.15, green: 0.15, blue: 0.2, alpha: 1.0)
            wingRight.position = SCNVector3(x: wingOffset, y: 0, z: 0)
            wingRight.eulerAngles = SCNVector3(x: 0, y: 0, z: -CGFloat.pi / 2.0)
            coreNode.addChildNode(wingRight)
            
            // Luminescent Odyssey Divine Torus
            let torusGeo = SCNTorus(ringRadius: radius * 1.05, pipeRadius: 0.07)
            torusGeo.firstMaterial?.lightingModel = .constant
            torusGeo.firstMaterial?.diffuse.contents = NSColor(red: 0.0, green: 0.95, blue: 0.85, alpha: 1.0)
            torusGeo.firstMaterial?.emission.contents = NSColor(red: 0.0, green: 0.95, blue: 0.85, alpha: 1.0)
            
            let discNode = SCNNode(geometry: torusGeo)
            discNode.name = "odyssey_disc_\(i)"
            let discY: CGFloat = -CGFloat(height / 2.0) - 0.04
            discNode.position = SCNVector3(x: 0, y: discY, z: 0)
            
            segNode.addChildNode(coreNode)
            segNode.addChildNode(discNode)
            
            let yPos: CGFloat = CGFloat(totalSegments - 1 - i) * 0.62 - 1.8
            segNode.position = SCNVector3(x: 0, y: yPos, z: 0)
            spineAssembly.addChildNode(segNode)
        }
        
        // 4. Golden Mask of Agamemnon
        let maskNode = SCNNode()
        maskNode.name = "maskOfAgamemnon"
        
        let maskSphere = SCNSphere(radius: 0.88)
        maskSphere.firstMaterial?.lightingModel = .physicallyBased
        maskSphere.firstMaterial?.diffuse.contents = NSColor(red: 0.95, green: 0.82, blue: 0.35, alpha: 1.0)
        maskSphere.firstMaterial?.metalness.contents = 0.95
        maskSphere.firstMaterial?.roughness.contents = 0.18
        maskNode.geometry = maskSphere
        
        let maskY: CGFloat = CGFloat(totalSegments) * 0.62 - 1.4
        maskNode.position = SCNVector3(x: 0, y: maskY, z: 0)
        
        // Spartan Helmet Crest
        let crestGeo = SCNCapsule(capRadius: 0.14, height: 1.3)
        crestGeo.firstMaterial?.diffuse.contents = NSColor(red: 0.85, green: 0.12, blue: 0.22, alpha: 1.0)
        let crestNode = SCNNode(geometry: crestGeo)
        crestNode.position = SCNVector3(x: 0, y: 0.85, z: -0.1)
        crestNode.eulerAngles = SCNVector3(x: 0.4, y: 0, z: 0)
        maskNode.addChildNode(crestNode)
        
        // Stylized Obsidian Audio Relics
        let leftPodRelic = SCNNode(geometry: SCNCylinder(radius: 0.18, height: 0.55))
        leftPodRelic.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
        leftPodRelic.position = SCNVector3(x: -0.98, y: -0.05, z: 0)
        leftPodRelic.eulerAngles = SCNVector3(x: 0, y: 0, z: 0.25)
        maskNode.addChildNode(leftPodRelic)
        
        let rightPodRelic = SCNNode(geometry: SCNCylinder(radius: 0.18, height: 0.55))
        rightPodRelic.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.12, green: 0.12, blue: 0.18, alpha: 1.0)
        rightPodRelic.position = SCNVector3(x: 0.98, y: -0.05, z: 0)
        rightPodRelic.eulerAngles = SCNVector3(x: 0, y: 0, z: -0.25)
        maskNode.addChildNode(rightPodRelic)
        
        spineAssembly.addChildNode(maskNode)
        scene.rootNode.addChildNode(spineAssembly)
        
        return scnView
    }
    
    public func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene,
              let spineAssembly = scene.rootNode.childNode(withName: "agamemnonSpineAssembly", recursively: false),
              let maskNode = spineAssembly.childNode(withName: "maskOfAgamemnon", recursively: false) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let pRad = CGFloat(pitch * .pi / 180.0)
        let rRad = CGFloat(roll * .pi / 180.0)
        let yRad = CGFloat(yaw * .pi / 180.0)
        
        // Natural Mirror Mode Reflection
        maskNode.eulerAngles = SCNVector3(x: pRad, y: yRad, z: -rRad)
        
        let totalSegments = 8
        for i in 0..<totalSegments {
            if let segNode = spineAssembly.childNode(withName: "odyssey_vertebra_\(i)", recursively: false) {
                let fraction = CGFloat(totalSegments - i) / CGFloat(totalSegments)
                segNode.eulerAngles = SCNVector3(x: pRad * fraction * 0.72, y: yRad * fraction * 0.65, z: -rRad * fraction * 0.72)
                
                if let discNode = segNode.childNode(withName: "odyssey_disc_\(i)", recursively: false) {
                    let auraColor: NSColor
                    if postureScore >= 80 {
                        auraColor = NSColor(red: 0.0, green: 0.95, blue: 0.85, alpha: 1.0)
                    } else if postureScore >= 60 {
                        auraColor = NSColor(red: 1.0, green: 0.65, blue: 0.15, alpha: 1.0)
                    } else {
                        auraColor = NSColor(red: 0.95, green: 0.15, blue: 0.28, alpha: 1.0)
                    }
                    discNode.geometry?.firstMaterial?.diffuse.contents = auraColor
                    discNode.geometry?.firstMaterial?.emission.contents = auraColor
                }
            }
        }
        
        SCNTransaction.commit()
    }
}
