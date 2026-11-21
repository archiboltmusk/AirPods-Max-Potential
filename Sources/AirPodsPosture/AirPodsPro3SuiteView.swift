import SwiftUI

/// AirPods Pro 3 Next-Gen Feature Suite View.
/// Delivers medical audiometry, acoustic dosimeters, teeth-click micro-gestures,
/// dynamic conversation ducking, and tympanic thermal sensing to any AirPods model.
public struct AirPodsPro3SuiteView: View {
    @ObservedObject var audiogram = ClinicalAudiogramEngine.shared
    @ObservedObject var dosimeter = NoiseDosimeterEngine.shared
    @ObservedObject var teethGestures = TeethClickGestureEngine.shared
    @ObservedObject var ducking = ConversationDuckingEngine.shared
    @ObservedObject var thermal = TympanicThermalEstimator.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header Bar (Apple HIG Glass)
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "sparkles.tv.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.purple)
                        .frame(width: 40, height: 40)
                        .background(Color.purple.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("AirPods Pro 3 Intelligence Suite")
                                .font(.system(size: 20, weight: .bold))
                            
                            Text("PRO 3 ARCHITECTURE")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.purple.opacity(0.15))
                                .foregroundColor(.purple)
                                .clipShape(Capsule())
                        }
                        
                        Text("Porting next-gen medical audiometry, acoustic dosimeters, teeth micro-gestures & tympanic thermometry")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 16)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.purple)
                            .frame(width: 7, height: 7)
                        Text("5 Engines Synced")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(.purple)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.purple.opacity(0.10))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 2)
                
                // 1. Clinical Audiogram & Adaptive Speech Clarifier
                Pro3Card(
                    title: "Clinical Audiogram & Adaptive Speech Clarifier",
                    subtitle: "OTC medical-grade pure-tone audiometry test across 6 frequency bands (250Hz - 8kHz) with parametric speech EQ.",
                    icon: "waveform.path.ecg",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Hearing Profile: \(audiogram.hearingGrade)")
                                    .font(.subheadline.bold())
                                Text(audiogram.testCompleted ? "Personalized parametric EQ active." : "Run standard 6-tone test to calibrate.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if !audiogram.isTestActive {
                                Button(audiogram.testCompleted ? "Re-Test Audiogram" : "Start Audiogram Test") {
                                    audiogram.startAudiogramTest()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            } else {
                                Button("Cancel Test") {
                                    audiogram.cancelTest()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        if audiogram.isTestActive {
                            VStack(alignment: .leading, spacing: 10) {
                                HStack {
                                    Image(systemName: "speaker.wave.2.fill")
                                        .foregroundColor(.blue)
                                    Text("Testing \(audiogram.currentEar.rawValue) at \(audiogram.currentTestingHz) Hz")
                                        .font(.system(size: 13, weight: .semibold))
                                    Spacer()
                                    Text("Band \(audiogram.currentFrequencyIndex + 1) of 6")
                                        .font(.caption2.bold())
                                        .foregroundColor(.secondary)
                                }
                                
                                HStack(spacing: 12) {
                                    Button(action: {
                                        audiogram.recordCurrentThreshold(audible: true)
                                    }) {
                                        Label("I Hear the Tone", systemImage: "checkmark.circle.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.blue)
                                    
                                    Button(action: {
                                        audiogram.recordCurrentThreshold(audible: false)
                                    }) {
                                        Label("Cannot Hear (Louder)", systemImage: "arrow.up.circle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                }
                            }
                            .padding(12)
                            .background(Color.blue.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        }
                        
                        // Frequency Spectrum Threshold Grid
                        VStack(alignment: .leading, spacing: 6) {
                            Text("AUDIOGRAM FREQUENCY PROFILE (dB HEARING LEVEL)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 8) {
                                ForEach(audiogram.testFrequencies, id: \.self) { freq in
                                    let lVal = audiogram.leftThresholds[freq] ?? 15.0
                                    let rVal = audiogram.rightThresholds[freq] ?? 15.0
                                    
                                    VStack(spacing: 4) {
                                        Text("\(freq >= 1000 ? "\(freq/1000)k" : "\(freq)")")
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.secondary)
                                        
                                        HStack(spacing: 2) {
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.blue)
                                                .frame(width: 5, height: CGFloat(max(6, lVal * 1.5)))
                                            RoundedRectangle(cornerRadius: 2)
                                                .fill(Color.purple)
                                                .frame(width: 5, height: CGFloat(max(6, rVal * 1.5)))
                                        }
                                        .frame(height: 50, alignment: .bottom)
                                        
                                        Text(String(format: "%.0fdB", (lVal + rVal)/2.0))
                                            .font(.system(size: 9, weight: .semibold, design: .rounded))
                                            .foregroundColor(.primary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 6)
                                    .background(Color.primary.opacity(0.03))
                                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                                }
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // Adaptive Speech Clarifier Toggle
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Toggle("Adaptive Speech Clarifier Hearing Aid", isOn: $audiogram.isHearingAidModeEnabled)
                                    .toggleStyle(.switch)
                                    .font(.subheadline.bold())
                                Text("Inverts your audiogram attenuation curve to boost dialogue and vocal clarity.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "plus.forwardslash.minus")
                                    .font(.caption2)
                                Text("+\(audiogram.dialogueClarityBoostPercent)% Vocal Boost")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.blue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.blue.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                // 2. OSHA / NIOSH Noise Dosimeter & Acoustic Shock Shield
                Pro3Card(
                    title: "NIOSH Sound Pressure Dosimeter & Acoustic Shield",
                    subtitle: "Continuous ear-canal decibel monitoring (dBA) with 8-hour permissible exposure tracking & instantaneous transient spike dampening.",
                    icon: "ear.badge.checkmark",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 16) {
                            // Decibel Gauge
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", dosimeter.currentDecibelsDba))
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(dosimeter.currentDecibelsDba > 85 ? .red : (dosimeter.currentDecibelsDba > 75 ? .orange : .green))
                                    Text("dBA")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.secondary)
                                }
                                Text(dosimeter.dosimeterRating)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Daily Permissible Dose Progress
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Daily Permissible Dose")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                
                                HStack(spacing: 6) {
                                    ProgressView(value: min(100.0, dosimeter.dailyNoiseDosePercent), total: 100.0)
                                        .progressViewStyle(.linear)
                                        .frame(width: 110)
                                        .tint(dosimeter.dailyNoiseDosePercent > 80 ? Color.red : Color.green)
                                    
                                    Text(String(format: "%.1f%%", dosimeter.dailyNoiseDosePercent))
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                
                                Text("Peak: \(String(format: "%.1f", dosimeter.peakDecibelRecorded)) dBA")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Divider()
                            .padding(.vertical, 2)
                        
                        // Acoustic Spike Cushion Shield
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Toggle("Acoustic Shock Cushion Shield", isOn: $dosimeter.acousticSpikeShieldActive)
                                    .toggleStyle(.switch)
                                    .font(.subheadline.bold())
                                Text("Compresses sudden transient sound blasts (>85 dBA under 5ms) to prevent acoustic trauma.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "shield.lefthalf.filled")
                                    .font(.caption2)
                                Text("\(dosimeter.spikesBlockedToday) Spikes Blocked")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                    }
                }
                
                // 3. Touchless Teeth-Click & Molar Tap Micro-Gestures
                Pro3Card(
                    title: "Touchless Teeth-Click Micro-Gesture Sentinel",
                    subtitle: "Analyzes in-ear bone conduction impulses and acoustic shockwaves from subtle teeth clicks to trigger hands-free macOS actions.",
                    icon: "hand.tap.fill",
                    accentColor: .indigo
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Enable Teeth Micro-Gestures", isOn: $teethGestures.isGestureControlEnabled)
                                .toggleStyle(.switch)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Picker("Sensitivity", selection: $teethGestures.sensitivityLevel) {
                                ForEach(TeethClickGestureEngine.GestureSensitivity.allCases) { sens in
                                    Text(sens.rawValue).tag(sens)
                                }
                            }
                            .pickerStyle(.menu)
                            .fixedSize()
                        }
                        
                        // Gesture Map & Live Impulse Energy
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text("Double-Click")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.indigo.opacity(0.12))
                                        .foregroundColor(.indigo)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text("Mute / Unmute System Mic")
                                        .font(.caption)
                                }
                                
                                HStack(spacing: 8) {
                                    Text("Triple-Click")
                                        .font(.system(size: 11, weight: .bold, design: .monospaced))
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.indigo.opacity(0.12))
                                        .foregroundColor(.indigo)
                                        .clipShape(RoundedRectangle(cornerRadius: 4))
                                    Text("Play / Pause Active Media")
                                        .font(.caption)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Last Gesture")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text(teethGestures.lastGestureRecognized)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.indigo)
                                
                                Button("Simulate Tooth Click") {
                                    teethGestures.processAcousticImpulse(energy: 0.55)
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                // 4. Conversation Awareness & Dynamic Media Ducking
                Pro3Card(
                    title: "Smart Conversation Awareness & Auto-Ducking",
                    subtitle: "Sub-80ms voice activity detector that attenuates media playback volume to 20% when you speak, automatically restoring it after conversation ceases.",
                    icon: "bubble.left.and.bubble.right.fill",
                    accentColor: .orange
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Auto-Duck Audio When Speaking", isOn: $ducking.isDuckingEnabled)
                                .toggleStyle(.switch)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Text("\(ducking.duckEventsCountToday) Duck Events Today")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ducking.statusMessage)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(ducking.isConversationActive ? .orange : .primary)
                                
                                Text(ducking.isConversationActive ? "Volume attenuated to 20% • Clarifying speech" : "Volume at 100% nominal.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            // Audio Volume Level Bar
                            VStack(alignment: .trailing, spacing: 2) {
                                Text("Output Volume: \(Int(ducking.currentDuckLevel * 100))%")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                ProgressView(value: ducking.currentDuckLevel, total: 1.0)
                                    .progressViewStyle(.linear)
                                    .frame(width: 90)
                                    .tint(ducking.isConversationActive ? Color.orange : Color.green)
                            }
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                // 5. Tympanic Membrane Thermal & Metabolic Exertion
                Pro3Card(
                    title: "Tympanic Thermal & Metabolic Exertion Sentry",
                    subtitle: "Estimates ear canal core body temperature and cognitive heat load via carotid pulse velocity and respiratory rhythms.",
                    icon: "thermometer.sun.fill",
                    accentColor: .red
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.2f°C", thermal.estimatedEarTempCelsius))
                                        .font(.system(size: 30, weight: .bold, design: .rounded))
                                        .foregroundColor(thermal.thermalZone.color)
                                    Text(String(format: "(%.1f°F)", thermal.estimatedEarTempFahrenheit))
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                Text(thermal.thermalStatusMessage)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                HStack(spacing: 4) {
                                    Image(systemName: thermal.thermalZone.icon)
                                        .font(.caption2)
                                    Text(thermal.thermalZone.rawValue)
                                        .font(.system(size: 10, weight: .bold))
                                }
                                .foregroundColor(thermal.thermalZone.color)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(thermal.thermalZone.color.opacity(0.12))
                                .clipShape(Capsule())
                                
                                Button("Calibrate Baseline") {
                                    thermal.calibrateBaseline()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        
                        // Metabolic Exertion Bar
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Metabolic Exertion Index")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text(String(format: "%.0f%% Load", thermal.thermalExertionIndex))
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                                    .foregroundColor(.secondary)
                            }
                            
                            ProgressView(value: thermal.thermalExertionIndex, total: 100.0)
                                .progressViewStyle(.linear)
                                .tint(thermal.thermalExertionIndex > 60 ? Color.orange : Color.green)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// Reusable Apple Glass Pro 3 Card
struct Pro3Card<Content: View>: View {
    let title: String
    let subtitle: String
    let icon: String
    let accentColor: Color
    let content: Content
    
    init(title: String, subtitle: String, icon: String, accentColor: Color, @ViewBuilder content: () -> Content) {
        self.title = title
        self.subtitle = subtitle
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 32, height: 32)
                    .background(accentColor.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 14, weight: .semibold))
                    Text(subtitle)
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
            }
            
            content
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .appleGlass(cornerRadius: 16, opacity: 0.35)
    }
}
