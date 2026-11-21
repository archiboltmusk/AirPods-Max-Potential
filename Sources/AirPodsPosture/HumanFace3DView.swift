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
        cameraNode.camera?.fieldOfView = 42
        cameraNode.camera?.motionBlurIntensity = 0.3
        cameraNode.position = SCNVector3(x: 0, y: 0.2, z: 5.6)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Studio Portrait Lighting
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1500
        keyLight.light?.color = NSColor.white
        keyLight.position = SCNVector3(x: 3.0, y: 3.5, z: 4.5)
        scene.rootNode.addChildNode(keyLight)
        
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .omni
        rimLight.light?.intensity = 1000
        rimLight.light?.color = NSColor.cyan
        rimLight.position = SCNVector3(x: -3.5, y: 1.5, z: -3.0)
        scene.rootNode.addChildNode(rimLight)
        
        let softAmbient = SCNNode()
        softAmbient.light = SCNLight()
        softAmbient.light?.type = .ambient
        softAmbient.light?.intensity = 550
        softAmbient.light?.color = NSColor(white: 0.35, alpha: 1.0)
        scene.rootNode.addChildNode(softAmbient)
        
        // 3. Human Head Root Assembly
        let headRoot = SCNNode()
        headRoot.name = "humanHeadAssembly"
        
        // Skin Material (Clean Apple Memoji / Studio Matte Finish)
        let skinMaterial = SCNMaterial()
        skinMaterial.lightingModel = .physicallyBased
        skinMaterial.diffuse.contents = NSColor(red: 0.94, green: 0.82, blue: 0.74, alpha: 1.0)
        skinMaterial.roughness.contents = 0.55
        skinMaterial.metalness.contents = 0.05
        
        // Cranium / Head (Smooth Proportional Human Head Geometry)
        let craniumGeo = SCNSphere(radius: 1.0)
        craniumGeo.segmentCount = 48
        craniumGeo.materials = [skinMaterial]
        
        let craniumNode = SCNNode(geometry: craniumGeo)
        craniumNode.scale = SCNVector3(x: 0.92, y: 1.15, z: 1.05)
        craniumNode.position = SCNVector3(x: 0, y: 0.2, z: 0)
        headRoot.addChildNode(craniumNode)
        
        // Jaw / Chin (Natural Taper)
        let jawGeo = SCNCapsule(capRadius: 0.38, height: 0.9)
        jawGeo.materials = [skinMaterial]
        let jawNode = SCNNode(geometry: jawGeo)
        jawNode.scale = SCNVector3(x: 0.9, y: 0.85, z: 0.9)
        jawNode.position = SCNVector3(x: 0, y: -0.65, z: 0.32)
        jawNode.eulerAngles = SCNVector3(x: -0.28, y: 0, z: 0)
        headRoot.addChildNode(jawNode)
        
        // Human Nose
        let noseGeo = SCNCapsule(capRadius: 0.09, height: 0.42)
        noseGeo.materials = [skinMaterial]
        let noseNode = SCNNode(geometry: noseGeo)
        noseNode.position = SCNVector3(x: 0, y: -0.05, z: 1.06)
        noseNode.eulerAngles = SCNVector3(x: 0.35, y: 0, z: 0)
        headRoot.addChildNode(noseNode)
        
        // Left Eye (Stylized Dark Iris with Specular Reflection)
        let eyeMaterial = SCNMaterial()
        eyeMaterial.diffuse.contents = NSColor(red: 0.12, green: 0.15, blue: 0.20, alpha: 1.0)
        eyeMaterial.roughness.contents = 0.1
        eyeMaterial.metalness.contents = 0.4
        
        let leftEye = SCNNode(geometry: SCNSphere(radius: 0.12))
        leftEye.geometry?.materials = [eyeMaterial]
        leftEye.position = SCNVector3(x: -0.36, y: 0.18, z: 0.95)
        headRoot.addChildNode(leftEye)
        
        // Right Eye
        let rightEye = SCNNode(geometry: SCNSphere(radius: 0.12))
        rightEye.geometry?.materials = [eyeMaterial]
        rightEye.position = SCNVector3(x: 0.36, y: 0.18, z: 0.95)
        headRoot.addChildNode(rightEye)
        
        // Eyebrows
        let browMaterial = SCNMaterial()
        browMaterial.diffuse.contents = NSColor(red: 0.2, green: 0.15, blue: 0.1, alpha: 1.0)
        
        let leftBrow = SCNNode(geometry: SCNCylinder(radius: 0.035, height: 0.32))
        leftBrow.geometry?.materials = [browMaterial]
        leftBrow.position = SCNVector3(x: -0.36, y: 0.36, z: 0.96)
        leftBrow.eulerAngles = SCNVector3(x: 0, y: 0, z: 1.45)
        headRoot.addChildNode(leftBrow)
        
        let rightBrow = SCNNode(geometry: SCNCylinder(radius: 0.035, height: 0.32))
        rightBrow.geometry?.materials = [browMaterial]
        rightBrow.position = SCNVector3(x: 0.36, y: 0.36, z: 0.96)
        rightBrow.eulerAngles = SCNVector3(x: 0, y: 0, z: -1.45)
        headRoot.addChildNode(rightBrow)
        
        // Realistic Human Neck (Cervical Column that tilts smoothly)
        let neckMaterial = SCNMaterial()
        neckMaterial.lightingModel = .physicallyBased
        neckMaterial.diffuse.contents = NSColor(red: 0.91, green: 0.78, blue: 0.70, alpha: 1.0)
        neckMaterial.roughness.contents = 0.6
        
        let neckGeo = SCNCylinder(radius: 0.52, height: 1.2)
        neckGeo.materials = [neckMaterial]
        let neckNode = SCNNode(geometry: neckGeo)
        neckNode.name = "neckNode"
        neckNode.position = SCNVector3(x: 0, y: -1.35, z: -0.05)
        headRoot.addChildNode(neckNode)
        
        // AirPods Pro 2 (Clean White Earbuds with Silicone Tips in Ears)
        let podMaterial = SCNMaterial()
        podMaterial.diffuse.contents = NSColor.white
        podMaterial.roughness.contents = 0.15
        podMaterial.metalness.contents = 0.8
        
        // Left AirPod Pro 2
        let leftAirPod = SCNNode()
        let leftHead = SCNNode(geometry: SCNSphere(radius: 0.16))
        leftHead.geometry?.materials = [podMaterial]
        let leftStem = SCNNode(geometry: SCNCylinder(radius: 0.055, height: 0.42))
        leftStem.geometry?.materials = [podMaterial]
        leftStem.position = SCNVector3(x: 0, y: -0.22, z: 0.04)
        leftStem.eulerAngles = SCNVector3(x: 0.3, y: 0, z: 0)
        leftAirPod.addChildNode(leftHead)
        leftAirPod.addChildNode(leftStem)
        leftAirPod.position = SCNVector3(x: -0.98, y: 0.02, z: 0.08)
        leftAirPod.eulerAngles = SCNVector3(x: 0, y: 0, z: 0.15)
        headRoot.addChildNode(leftAirPod)
        
        // Right AirPod Pro 2
        let rightAirPod = SCNNode()
        let rightHead = SCNNode(geometry: SCNSphere(radius: 0.16))
        rightHead.geometry?.materials = [podMaterial]
        let rightStem = SCNNode(geometry: SCNCylinder(radius: 0.055, height: 0.42))
        rightStem.geometry?.materials = [podMaterial]
        rightStem.position = SCNVector3(x: 0, y: -0.22, z: 0.04)
        rightStem.eulerAngles = SCNVector3(x: 0.3, y: 0, z: 0)
        rightAirPod.addChildNode(rightHead)
        rightAirPod.addChildNode(rightStem)
        rightAirPod.position = SCNVector3(x: 0.98, y: 0.02, z: 0.08)
        rightAirPod.eulerAngles = SCNVector3(x: 0, y: 0, z: -0.15)
        headRoot.addChildNode(rightAirPod)
        
        // Posture Health Glowing Halo (Floating Above Head)
        let haloGeo = SCNTorus(ringRadius: 0.85, pipeRadius: 0.035)
        haloGeo.firstMaterial?.lightingModel = .constant
        haloGeo.firstMaterial?.diffuse.contents = NSColor.cyan
        haloGeo.firstMaterial?.emission.contents = NSColor.cyan
        
        let haloNode = SCNNode(geometry: haloGeo)
        haloNode.name = "postureHaloNode"
        haloNode.position = SCNVector3(x: 0, y: 1.45, z: 0)
        haloNode.eulerAngles = SCNVector3(x: 0.18, y: 0, z: 0)
        headRoot.addChildNode(haloNode)
        
        scene.rootNode.addChildNode(headRoot)
        
        return scnView
    }
    
    public func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene,
              let headRoot = scene.rootNode.childNode(withName: "humanHeadAssembly", recursively: false),
              let haloNode = headRoot.childNode(withName: "postureHaloNode", recursively: false),
              let neckNode = headRoot.childNode(withName: "neckNode", recursively: false) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.08
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        
        let pRad = CGFloat(pitch * .pi / 180.0)
        let rRad = CGFloat(roll * .pi / 180.0)
        let yRad = CGFloat(yaw * .pi / 180.0)
        
        // Rotate human head to mimic user's live AirPods angles
        headRoot.eulerAngles = SCNVector3(x: -pRad, y: yRad, z: -rRad)
        
        // Articulate neck counter-bend for natural human kinesiology
        neckNode.eulerAngles = SCNVector3(x: pRad * 0.45, y: -yRad * 0.35, z: rRad * 0.45)
        
        // Color the Posture Halo
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
