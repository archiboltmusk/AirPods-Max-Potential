import Foundation
#if canImport(MultipeerConnectivity)
import MultipeerConnectivity
import Combine

/// Multiplatform Peer-to-Peer Transceiver for Apple Ecosystem.
/// Works out of the box with zero Wi-Fi network setup across Mac, iPhone, and iPad.
@MainActor
public final class MultipeerEcosystemTransceiver: NSObject, ObservableObject {
    public static let shared = MultipeerEcosystemTransceiver()
    
    public static let serviceType = "airpods-iq"
    
    @Published public var connectedPeerNames: [String] = []
    @Published public var latestPacket: PostureTelemetryPacket?
    @Published public var isSessionActive: Bool = false
    @Published public var localRole: DeviceEcosystemRole = .macHub
    
    private nonisolated(unsafe) var peerID: MCPeerID!
    private nonisolated(unsafe) var session: MCSession!
    private nonisolated(unsafe) var advertiser: MCNearbyServiceAdvertiser?
    private nonisolated(unsafe) var browser: MCNearbyServiceBrowser?
    
    private override init() {
        super.init()
        #if os(macOS)
        self.localRole = .macHub
        let hostName = Host.current().localizedName ?? "Mac"
        #elseif os(iOS)
        #if targetEnvironment(macCatalyst)
        self.localRole = .macHub
        let hostName = "Mac Catalyst"
        #else
        self.localRole = .iphoneCompanion
        let hostName = "iPhone"
        #endif
        #elseif os(watchOS)
        self.localRole = .appleWatchSentinel
        let hostName = "Apple Watch"
        #else
        self.localRole = .iphoneCompanion
        let hostName = "Apple Device"
        #endif
        
        self.peerID = MCPeerID(displayName: hostName)
        self.session = MCSession(peer: self.peerID, securityIdentity: nil, encryptionPreference: .required)
        self.session.delegate = self
        
        startBroadcasting()
    }
    
    public func setRole(_ role: DeviceEcosystemRole) {
        self.localRole = role
    }
    
    public func startBroadcasting() {
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: ["role": localRole.rawValue], serviceType: Self.serviceType)
        advertiser?.delegate = self
        advertiser?.startAdvertisingPeer()
        
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: Self.serviceType)
        browser?.delegate = self
        browser?.startBrowsingForPeers()
        
        isSessionActive = true
    }
    
    public func stopBroadcasting() {
        advertiser?.stopAdvertisingPeer()
        browser?.stopBrowsingForPeers()
        session.disconnect()
        isSessionActive = false
    }
    
    public func broadcastTelemetry(_ packet: PostureTelemetryPacket) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(packet)
            try session.send(data, toPeers: session.connectedPeers, with: .unreliable)
        } catch {
            // Drop packet if network congested
        }
    }
    
    public func sendHapticCommandToWatchOrIPhone(_ haptic: HapticCommandPacket) {
        guard !session.connectedPeers.isEmpty else { return }
        do {
            let data = try JSONEncoder().encode(haptic)
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            // Fallback
        }
    }
}

extension MultipeerEcosystemTransceiver: MCSessionDelegate {
    public nonisolated func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let peerNames = session.connectedPeers.map { $0.displayName }
        Task { @MainActor in
            self.connectedPeerNames = peerNames
        }
    }
    
    public nonisolated func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        if let packet = try? JSONDecoder().decode(PostureTelemetryPacket.self, from: data) {
            Task { @MainActor in
                self.latestPacket = packet
            }
        }
    }
    
    public nonisolated func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    public nonisolated func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    public nonisolated func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}

extension MultipeerEcosystemTransceiver: MCNearbyServiceAdvertiserDelegate {
    public nonisolated func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        invitationHandler(true, self.session)
    }
}

extension MultipeerEcosystemTransceiver: MCNearbyServiceBrowserDelegate {
    public nonisolated func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        browser.invitePeer(peerID, to: self.session, withContext: nil, timeout: 10)
    }
    
    public nonisolated func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {}
}
#endif
