import SwiftUI
import SceneKit

public struct AnatomicalSpine3DView: NSViewRepresentable {
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
        cameraNode.camera?.fieldOfView = 48
        cameraNode.position = SCNVector3(x: 0, y: 0.5, z: 7.2)
        scene.rootNode.addChildNode(cameraNode)
        
        // 2. Cinematic Lighting: Key, Fill, and Ambient Backlight
        let keyLight = SCNNode()
        keyLight.light = SCNLight()
        keyLight.light?.type = .omni
        keyLight.light?.intensity = 1200
        keyLight.light?.color = NSColor.cyan
        keyLight.position = SCNVector3(x: 3, y: 4, z: 5)
        scene.rootNode.addChildNode(keyLight)
        
        let rimLight = SCNNode()
        rimLight.light = SCNLight()
        rimLight.light?.type = .omni
        rimLight.light?.intensity = 900
        rimLight.light?.color = NSColor.magenta
        rimLight.position = SCNVector3(x: -4, y: 2, z: -3)
        scene.rootNode.addChildNode(rimLight)
        
        let ambientLight = SCNNode()
        ambientLight.light = SCNLight()
        ambientLight.light?.type = .ambient
        ambientLight.light?.intensity = 450
        ambientLight.light?.color = NSColor(white: 0.25, alpha: 1.0)
        scene.rootNode.addChildNode(ambientLight)
        
        // 3. Build Kinematic Spine Rig (C1 through C7 vertebrae + skull anchor)
        let spineRoot = SCNNode()
        spineRoot.name = "spineRoot"
        
        let vertebraeCount = 7
        for i in 0..<vertebraeCount {
            let vNode = SCNNode()
            vNode.name = "vertebra_\(i)"
            
            // Vertebral body geometry (rounded chamfer cylinder)
            let radius: CGFloat = 0.42 - CGFloat(i) * 0.02
            let height: CGFloat = 0.28
            let cyl = SCNCylinder(radius: radius, height: height)
            cyl.firstMaterial?.diffuse.contents = NSColor(white: 0.88, alpha: 1.0)
            cyl.firstMaterial?.lightingModel = .physicallyBased
            cyl.firstMaterial?.roughness.contents = 0.3
            cyl.firstMaterial?.metalness.contents = 0.7
            
            let cylNode = SCNNode(geometry: cyl)
            
            // Intervertebral Disc geometry (luminescent glowing ring)
            let disc = SCNTorus(ringRadius: radius * 0.95, pipeRadius: 0.08)
            disc.firstMaterial?.diffuse.contents = NSColor.cyan
            disc.firstMaterial?.emission.contents = NSColor.cyan
            disc.firstMaterial?.lightingModel = .constant
            
            let discNode = SCNNode(geometry: disc)
            discNode.name = "disc_\(i)"
            let discY: CGFloat = -CGFloat(height / 2.0) - 0.05
            discNode.position = SCNVector3(x: 0, y: discY, z: 0)
            
            vNode.addChildNode(cylNode)
            vNode.addChildNode(discNode)
            
            // Stack vertebrae vertically
            let yPos: CGFloat = CGFloat(vertebraeCount - 1 - i) * 0.55 - 1.2
            vNode.position = SCNVector3(x: 0, y: yPos, z: 0)
            spineRoot.addChildNode(vNode)
        }
        
        // 4. Skull Base / AirPods Rig Node at the top
        let skullNode = SCNNode()
        skullNode.name = "skullNode"
        let skullGeo = SCNSphere(radius: 0.75)
        skullGeo.firstMaterial?.diffuse.contents = NSColor(white: 0.95, alpha: 0.9)
        skullGeo.firstMaterial?.lightingModel = .physicallyBased
        skullGeo.firstMaterial?.roughness.contents = 0.2
        skullGeo.firstMaterial?.metalness.contents = 0.85
        skullNode.geometry = skullGeo
        let skullY: CGFloat = CGFloat(vertebraeCount) * 0.55 - 1.0
        skullNode.position = SCNVector3(x: 0, y: skullY, z: 0)
        
        // Stylized AirPods attached to the skull
        let leftPod = SCNNode(geometry: SCNCapsule(capRadius: 0.12, height: 0.6))
        leftPod.geometry?.firstMaterial?.diffuse.contents = NSColor.white
        leftPod.position = SCNVector3(x: -0.85, y: -0.1, z: 0)
        leftPod.eulerAngles = SCNVector3(x: 0, y: 0, z: 0.2)
        skullNode.addChildNode(leftPod)
        
        let rightPod = SCNNode(geometry: SCNCapsule(capRadius: 0.12, height: 0.6))
        rightPod.geometry?.firstMaterial?.diffuse.contents = NSColor.white
        rightPod.position = SCNVector3(x: 0.85, y: -0.1, z: 0)
        rightPod.eulerAngles = SCNVector3(x: 0, y: 0, z: -0.2)
        skullNode.addChildNode(rightPod)
        
        spineRoot.addChildNode(skullNode)
        scene.rootNode.addChildNode(spineRoot)
        
        return scnView
    }
    
    public func updateNSView(_ nsView: SCNView, context: Context) {
        guard let scene = nsView.scene,
              let spineRoot = scene.rootNode.childNode(withName: "spineRoot", recursively: false),
              let skullNode = spineRoot.childNode(withName: "skullNode", recursively: false) else { return }
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.016
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .linear)
        
        // Convert degrees to radians in CGFloat
        let pRad = CGFloat(pitch * .pi / 180.0)
        let rRad = CGFloat(roll * .pi / 180.0)
        let yRad = CGFloat(yaw * .pi / 180.0)
        
        // Rotate skull in 1-to-1 natural mirror reflection
        skullNode.eulerAngles = SCNVector3(x: pRad, y: yRad, z: -rRad)
        
        // Articulate individual vertebrae along spine curve
        let vertebraeCount = 7
        for i in 0..<vertebraeCount {
            if let vNode = spineRoot.childNode(withName: "vertebra_\(i)", recursively: false) {
                let fraction = CGFloat(vertebraeCount - i) / CGFloat(vertebraeCount)
                vNode.eulerAngles = SCNVector3(x: pRad * fraction * 0.7, y: yRad * fraction * 0.6, z: -rRad * fraction * 0.7)
                
                // Color the intervertebral disc based on localized compressive stress
                if let discNode = vNode.childNode(withName: "disc_\(i)", recursively: false) {
                    let discColor: NSColor
                    if postureScore >= 80 {
                        discColor = NSColor.cyan
                    } else if postureScore >= 60 {
                        discColor = NSColor.orange
                    } else {
                        discColor = NSColor.systemRed
                    }
                    discNode.geometry?.firstMaterial?.diffuse.contents = discColor
                    discNode.geometry?.firstMaterial?.emission.contents = discColor
                }
            }
        }
        
        SCNTransaction.commit()
    }
}
