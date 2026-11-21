import SwiftUI
import SceneKit

public struct HumanFace3DView: NSViewRepresentable {
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
        scnView.allowsCameraControl = false
        
        // 1. Camera Node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.camera?.fieldOfView = 38
        cameraNode.position = SCNVector3(x: 0, y: 0.1, z: 6.8)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Cinematic Studio Portrait 3-Point Lighting
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1600
        keyLight.light?.color = NSColor(white: 0.98, alpha: 1.0)
        keyLight.position = SCNVector3(x: 3.5, y: 4.0, z: 5.5)
        scene.rootNode.addChildNode(keyLight)
        
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .omni
        rimLight.light?.intensity = 1100
        rimLight.light?.color = NSColor.cyan
        rimLight.position = SCNVector3(x: -4.0, y: 2.0, z: -3.5)
        scene.rootNode.addChildNode(rimLight)
        
        let fillLight = SCNNode()
        fillLight.light = SCNLight()
        fillLight.light?.type = .ambient
        fillLight.light?.intensity = 450
        fillLight.light?.color = NSColor(white: 0.32, alpha: 1.0)
        scene.rootNode.addChildNode(fillLight)
        
        // 3. Human Head Assembly Root
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
            
            // Apply Studio Porcelain / Silicone Skin Shader with Wireframe accent
            container.enumerateHierarchy { (node, _) in
                if let geo = node.geometry {
                    let skinMat = SCNMaterial()
                    skinMat.lightingModel = .physicallyBased
                    skinMat.diffuse.contents = NSColor(red: 0.90, green: 0.86, blue: 0.82, alpha: 1.0)
                    skinMat.roughness.contents = 0.42
                    skinMat.metalness.contents = 0.12
                    
                    geo.materials = [skinMat]
                }
            }
            
            // Normalize scale and center
            // Model bounding span is ~8.55 units; scale down to fit viewport cleanly
            container.scale = SCNVector3(x: 0.28, y: 0.28, z: 0.28)
            container.position = SCNVector3(x: 0, y: 0, z: 0)
            loadedMeshNode = container
        }
        
        if let meshNode = loadedMeshNode {
            headAssembly.addChildNode(meshNode)
        } else {
            // Procedural anatomical fallback
            let fallbackHead = SCNNode(geometry: SCNSphere(radius: 1.1))
            fallbackHead.geometry?.firstMaterial?.diffuse.contents = NSColor(red: 0.90, green: 0.86, blue: 0.82, alpha: 1.0)
            headAssembly.addChildNode(fallbackHead)
        }
        
        // 4. Photorealistic AirPods Pro 2 Fitted on the Ears
        let podMaterial = SCNMaterial()
        podMaterial.lightingModel = .physicallyBased
        podMaterial.diffuse.contents = NSColor.white
        podMaterial.metalness.contents = 0.85
        podMaterial.roughness.contents = 0.15
        
        // Left AirPod Pro 2
        let leftAirPod = SCNNode()
        let leftBody = SCNNode(geometry: SCNSphere(radius: 0.18))
        leftBody.geometry?.materials = [podMaterial]
        let leftStem = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.44))
        leftStem.geometry?.materials = [podMaterial]
        leftStem.position = SCNVector3(x: 0, y: -0.22, z: 0.04)
        leftStem.eulerAngles = SCNVector3(x: 0.35, y: 0, z: 0)
        leftAirPod.addChildNode(leftBody)
        leftAirPod.addChildNode(leftStem)
        leftAirPod.position = SCNVector3(x: -1.22, y: 0.02, z: -0.15)
        leftAirPod.eulerAngles = SCNVector3(x: 0, y: 0, z: 0.2)
        headAssembly.addChildNode(leftAirPod)
        
        // Right AirPod Pro 2
        let rightAirPod = SCNNode()
        let rightBody = SCNNode(geometry: SCNSphere(radius: 0.18))
        rightBody.geometry?.materials = [podMaterial]
        let rightStem = SCNNode(geometry: SCNCylinder(radius: 0.05, height: 0.44))
        rightStem.geometry?.materials = [podMaterial]
        rightStem.position = SCNVector3(x: 0, y: -0.22, z: 0.04)
        rightStem.eulerAngles = SCNVector3(x: 0.35, y: 0, z: 0)
        rightAirPod.addChildNode(rightBody)
        rightAirPod.addChildNode(rightStem)
        rightAirPod.position = SCNVector3(x: 1.22, y: 0.02, z: -0.15)
        rightAirPod.eulerAngles = SCNVector3(x: 0, y: 0, z: -0.2)
        headAssembly.addChildNode(rightAirPod)
        
        // 5. Luminescent Posture Halo (Aura of Neutral Lordosis)
        let haloGeo = SCNTorus(ringRadius: 1.15, pipeRadius: 0.035)
        haloGeo.firstMaterial?.lightingModel = .constant
        haloGeo.firstMaterial?.diffuse.contents = NSColor.cyan
        haloGeo.firstMaterial?.emission.contents = NSColor.cyan
        
        let haloNode = SCNNode(geometry: haloGeo)
        haloNode.name = "humanHaloNode"
        haloNode.position = SCNVector3(x: 0, y: 1.45, z: -0.1)
        haloNode.eulerAngles = SCNVector3(x: 0.15, y: 0, z: 0)
        headAssembly.addChildNode(haloNode)
        
        scene.rootNode.addChildNode(headAssembly)
        return scnView
    }
    
    public func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene,
              let headAssembly = scene.rootNode.childNode(withName: "humanHeadAssembly", recursively: false),
              let haloNode = headAssembly.childNode(withName: "humanHaloNode", recursively: false) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let pRad = CGFloat(pitch * .pi / 180.0)
        let rRad = CGFloat(roll * .pi / 180.0)
        let yRad = CGFloat(yaw * .pi / 180.0)
        
        // Rotate real 3D anatomical human head with AirPods Pro 2 orientation
        headAssembly.eulerAngles = SCNVector3(x: -pRad, y: yRad, z: -rRad)
        
        // Update Halo Status Color
        let haloColor: NSColor
        if postureScore >= 80 {
            haloColor = NSColor.cyan
        } else if postureScore >= 60 {
            haloColor = NSColor.orange
        } else {
            haloColor = NSColor.systemRed
        }
        haloNode.geometry?.firstMaterial?.diffuse.contents = haloColor
        haloNode.geometry?.firstMaterial?.emission.contents = haloColor
        
        SCNTransaction.commit()
    }
}
