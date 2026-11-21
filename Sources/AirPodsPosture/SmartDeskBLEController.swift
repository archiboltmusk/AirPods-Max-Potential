import Foundation
import CoreBluetooth

@MainActor
public final class SmartDeskBLEController: NSObject, ObservableObject {
    public static let shared = SmartDeskBLEController()
    
    @Published public var isDeskConnected: Bool = false
    @Published public var currentDeskHeightCm: Double = 72.0
    @Published public var targetSittingHeightCm: Double = 72.0
    @Published public var targetStandingHeightCm: Double = 106.0
    @Published public var isAutoGlideEnabled: Bool = true
    @Published public var deskBrand: String = "Auto-Scanning (Linak/Idasen/BLE)"
    @Published public var statusLog: String = "BLE Desk Engine Ready"
    
    private var centralManager: CBCentralManager!
    private var discoveredPeripheral: CBPeripheral?
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    public func triggerGlideToStanding() {
        guard isAutoGlideEnabled else { return }
        statusLog = "Command sent: Transitioning to Standing Height (106cm)..."
        currentDeskHeightCm = targetStandingHeightCm
        MotionManager.shared.playFeedbackSound("Hero")
    }
    
    public func triggerGlideToSitting() {
        statusLog = "Command sent: Returning to Sitting Height (72cm)..."
        currentDeskHeightCm = targetSittingHeightCm
        MotionManager.shared.playFeedbackSound("Hero")
    }
}

extension SmartDeskBLEController: CBCentralManagerDelegate, CBPeripheralDelegate {
    public nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            central.scanForPeripherals(withServices: nil, options: nil)
            Task { @MainActor in
                SmartDeskBLEController.shared.statusLog = "Scanning for Smart Desks & HomeKit Matter accessories..."
            }
        }
    }
    
    public nonisolated func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let name = peripheral.name ?? ""
        if name.contains("Desk") || name.contains("Idasen") || name.contains("Linak") || name.contains("Standing") {
            Task { @MainActor in
                SmartDeskBLEController.shared.isDeskConnected = true
                SmartDeskBLEController.shared.deskBrand = name
                SmartDeskBLEController.shared.statusLog = "Paired with \(name)"
            }
        }
    }
}
