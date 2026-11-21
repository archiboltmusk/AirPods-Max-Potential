import SwiftUI

public struct EcosystemBridgesView: View {
    @ObservedObject var sentinel = OpticalContinuitySentinel.shared
    @ObservedObject var watchBridge = AppleWatchBridgeManager.shared
    @ObservedObject var visionBridge = TrueDepthVisionBridgeManager.shared
    @ObservedObject var smartDesk = SmartDeskBLEController.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack(spacing: 12) {
                    Image(systemName: "applewatch.and.arrow.forward")
                        .font(.system(size: 28))
                        .foregroundColor(.blue)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Cross-Device Hardware Sensor Fusion")
                            .font(.title2.bold())
                        Text("Unify Apple Watch wrist kinematics, iPhone TrueDepth camera LiDAR, and Smart Bluetooth standing desks.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 8)
                
                // 0. FaceTime HD & Continuity Camera Optical Sentinel (AirPods In-Case Fallback)
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "camera.viewfinder")
                            .foregroundColor(.orange)
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("FaceTime HD / Continuity Optical Sentinel")
                                .font(.headline)
                            Text("Autonomous In-Case Fallback • Apple Neural Engine 30 FPS")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Circle()
                                .fill(sentinel.isRunning ? Color.green : Color.secondary)
                                .frame(width: 8, height: 8)
                            Text(sentinel.isRunning ? "Active (\(sentinel.opticalFps) FPS)" : "Standby (Sleeping)")
                                .font(.caption.bold())
                                .foregroundColor(sentinel.isRunning ? .green : .secondary)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.secondary.opacity(0.12))
                        .clipShape(Capsule())
                    }
                    
                    Text("Maintains uninterrupted posture monitoring when AirPods are docked in their charging case. Tracks 3-axis facial orientation, forward head craning (turtle neck in cm), and blink rates on-device. Zero video is ever recorded or transmitted.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "+%.1f cm", sentinel.forwardCraningCm))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(sentinel.forwardCraningCm > 4.0 ? .red : .teal)
                            Text("Forward Head Crane (Turtle Neck)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(sentinel.blinkRateBPM) BPM")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                            Text("Blink Rate (PERCLOS Fatigue)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(sentinel.faceDetected ? "Tracking Face" : "Acquiring...")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .foregroundColor(sentinel.faceDetected ? .green : .secondary)
                            Text(sentinel.currentCameraName)
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 6) {
                            Button(action: {
                                if sentinel.isRunning {
                                    sentinel.stopSentinel()
                                } else {
                                    sentinel.startSentinel()
                                }
                            }) {
                                HStack(spacing: 5) {
                                    Image(systemName: sentinel.isRunning ? "stop.circle.fill" : "play.circle.fill")
                                    Text(sentinel.isRunning ? "Pause Sentinel" : "Test Sentinel")
                                }
                                .font(.caption.bold())
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(sentinel.isRunning ? Color.red.opacity(0.15) : Color.orange.opacity(0.15))
                                .foregroundColor(sentinel.isRunning ? .red : .orange)
                                .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                            
                            Toggle("Auto-Fallback In Case", isOn: $sentinel.autoFallbackEnabled)
                                .toggleStyle(.switch)
                                .font(.caption2)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 1. Apple Watch Fusion
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "applewatch")
                            .foregroundColor(.pink)
                            .font(.title3)
                        Text("1. Apple Watch Wrist IMU & Taptic Feedback Engine")
                            .font(.headline)
                        Spacer()
                        Text(watchBridge.statusMessage)
                            .font(.caption.bold())
                            .foregroundColor(watchBridge.thoracicSlumpDetected ? .red : .green)
                    }
                    
                    Text("Combines AirPods cervical neck angles with Apple Watch forearm tilt and typing angles to identify Thoracic Spine Slumping (hunched upper back).")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(watchBridge.heartRateBPM)) BPM")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.pink)
                            Text("Apple Watch Optical Pulse")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(watchBridge.hrvSDNN)) ms")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.purple)
                            Text("Heart Rate Variability (SDNN)")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f°", watchBridge.wristPitch))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                            Text("Forearm Typing Angle")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("Silent Wrist Haptic Alerts", isOn: $watchBridge.hapticFeedbackEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 2. iPhone / iPad TrueDepth Vision Fusion
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "iphone.gen3")
                            .foregroundColor(.blue)
                            .font(.title3)
                        Text("2. iPhone TrueDepth & iPad LiDAR Skeleton Fusion")
                            .font(.headline)
                        Spacer()
                        Text(visionBridge.isPeerConnected ? "Streaming 3D Skeleton" : "Multipeer Standby")
                            .font(.caption.bold())
                            .foregroundColor(visionBridge.isPeerConnected ? .green : .secondary)
                    }
                    
                    Text("Place iPhone in front of your workspace. Stream 3D clavicle, shoulder level, and sternum coordinates via low-latency MultipeerConnectivity.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 16) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f°", visionBridge.shoulderImbalanceAngle))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(abs(visionBridge.shoulderImbalanceAngle) > 4.0 ? .orange : .green)
                            Text("Bilateral Shoulder Imbalance")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(String(format: "%.1f cm", visionBridge.sternumProtractionDistance))
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.teal)
                            Text("Sternum Forward Protraction")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().frame(height: 36)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(visionBridge.framesReceived)")
                                .font(.system(size: 26, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            Text("3D Vision Frames Ingested")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
                
                // 3. Smart Standing Desk BLE & HomeKit Controller
                VStack(alignment: .leading, spacing: 14) {
                    HStack {
                        Image(systemName: "table.furniture")
                            .foregroundColor(.orange)
                            .font(.title3)
                        Text("3. Smart Standing Desk Bluetooth & Matter Automation")
                            .font(.headline)
                        Spacer()
                        Text(smartDesk.statusLog)
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                    }
                    
                    Text("Connects over CoreBluetooth to automatic motorized standing desks (Linak, Idasen, Fully). Automatically transitions when sedentary slouch limits are reached.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    HStack(spacing: 20) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(Int(smartDesk.currentDeskHeightCm)) cm")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("Current Height")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Button("Glide to Standing (106cm)") {
                            smartDesk.triggerGlideToStanding()
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Glide to Sitting (72cm)") {
                            smartDesk.triggerGlideToSitting()
                        }
                        .buttonStyle(.bordered)
                        
                        Spacer()
                        
                        Toggle("Auto-Elevate Desk on Chronic Slouch", isOn: $smartDesk.isAutoGlideEnabled)
                            .toggleStyle(.switch)
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(10)
                }
                .padding()
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(12)
            }
            .padding(24)
        }
    }
}
