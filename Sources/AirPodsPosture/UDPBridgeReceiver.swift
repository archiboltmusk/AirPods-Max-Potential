import Foundation
import Network
import simd

public struct BridgePacketPayload: Codable {
    public let quaternion: [Double]?
    public let yprDegrees: [Double]?
    public let gyroscope: [Double]?
    public let accelerometer: [Double]?
    public let packetsPerSecond: Int?
    public let device: String?
}

public final class UDPBridgeReceiver: @unchecked Sendable {
    public static let shared = UDPBridgeReceiver()
    
    public var isListening: Bool = false
    public var lastReceivedDate: Date? = nil
    
    public var onPacket: (@MainActor (simd_quatd, SIMD3<Double>, SIMD3<Double>, Int, String) -> Void)?
    
    private var listener: NWListener?
    private let queue = DispatchQueue(label: "com.airpodsiq.udpreceiver")
    
    private init() {}
    
    public func start(port: UInt16 = 4243) {
        queue.async { [weak self] in
            guard let self = self, self.listener == nil else { return }
            
            do {
                let params = NWParameters.udp
                params.allowLocalEndpointReuse = true
                guard let nwPort = NWEndpoint.Port(rawValue: port) else { return }
                let listener = try NWListener(using: params, on: nwPort)
                
                listener.newConnectionHandler = { [weak self] connection in
                    self?.handleConnection(connection)
                }
                
                listener.stateUpdateHandler = { [weak self] state in
                    if case .ready = state {
                        self?.isListening = true
                    } else if case .failed = state {
                        self?.isListening = false
                    }
                }
                
                listener.start(queue: self.queue)
                self.listener = listener
            } catch {
                print("UDPBridgeReceiver start notice:", error.localizedDescription)
            }
        }
    }
    
    private func handleConnection(_ connection: NWConnection) {
        connection.start(queue: queue)
        receiveNextMessage(on: connection)
    }
    
    private func receiveNextMessage(on connection: NWConnection) {
        connection.receiveMessage { [weak self] content, _, isComplete, error in
            guard let self = self else { return }
            
            if let data = content {
                if let payload = try? JSONDecoder().decode(BridgePacketPayload.self, from: data) {
                    if let qArr = payload.quaternion, qArr.count == 4 {
                        let quat = simd_quatd(ix: qArr[1], iy: qArr[2], iz: qArr[3], r: qArr[0])
                        let gyroArr = payload.gyroscope ?? [0, 0, 0]
                        let accelArr = payload.accelerometer ?? [0, 0, 0]
                        let gyro = SIMD3<Double>(gyroArr[0], gyroArr[1], gyroArr[2])
                        let accel = SIMD3<Double>(accelArr[0], accelArr[1], accelArr[2])
                        let pps = payload.packetsPerSecond ?? 50
                        let device = payload.device ?? "AirPods Pro"
                        
                        self.lastReceivedDate = Date()
                        Task { @MainActor in
                            self.onPacket?(quat, gyro, accel, pps, device)
                        }
                    }
                }
            }
            
            if error == nil && !isComplete {
                self.receiveNextMessage(on: connection)
            }
        }
    }
    
    public func stop() {
        queue.async { [weak self] in
            self?.listener?.cancel()
            self?.listener = nil
            self?.isListening = false
        }
    }
}
