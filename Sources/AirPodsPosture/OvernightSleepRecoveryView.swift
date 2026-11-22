import SwiftUI

/// Overnight Sleep & Recovery Lab View.
/// Delivers slow-wave acoustic stimulation, positional sleep apnea nudges,
/// hypnagogic auto-fading, circadian REM smart alarms, and overnight AHI profiling.
public struct OvernightSleepRecoveryView: View {
    @ObservedObject var sws = SlowWaveSleepStimulatorEngine.shared
    @ObservedObject var posa = PositionalApneaNudgeEngine.shared
    @ObservedObject var hypnagogic = HypnagogicSleepOnsetEngine.shared
    @ObservedObject var alarm = CircadianSmartAlarmEngine.shared
    @ObservedObject var apnea = OvernightApneaSnoreProfiler.shared
    @ObservedObject var bruxism = NightBruxismSleepSentry.shared
    @ObservedObject var soundscape = AdaptiveNightSoundscapeEngine.shared
    @ObservedObject var dutyCycle = AdaptiveSleepDutyCycle.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header Bar (Apple HIG Glass)
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.indigo)
                        .frame(width: 40, height: 40)
                        .background(Color.indigo.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 6) {
                            Text("Overnight Sleep & Recovery Lab")
                                .font(.system(size: 20, weight: .bold))
                            
                            Text("CLINICAL SLEEP SUITE")
                                .font(.system(size: 9, weight: .bold))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.indigo.opacity(0.15))
                                .foregroundColor(.indigo)
                                .clipShape(Capsule())
                        }
                        
                        Text("Slow-wave pink noise pulses, positional apnea nudges, hypnagogic auto-fades & circadian REM smart alarms")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 16)
                    
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.indigo)
                            .frame(width: 7, height: 7)
                        Text(sws.currentSleepStage.rawValue)
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(sws.currentSleepStage.color)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.indigo.opacity(0.10))
                    .clipShape(Capsule())
                }
                .padding(.bottom, 2)
                
                // 1. Slow-Wave Sleep (SWS) Pink Noise Acoustic Stimulator
                SleepCard(
                    title: "Slow-Wave Sleep (SWS) Pink-Noise Acoustic Stimulator",
                    subtitle: "Synchronizes 0.8Hz pink-noise acoustic micro-pulses to delta slow-wave peaks during Stage 3 NREM sleep.",
                    icon: "waveform.path.badge.plus",
                    accentColor: .purple
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Toggle("Enable Phase-Locked SWS Stimulation", isOn: $sws.isStimulationEnabled)
                                    .toggleStyle(.switch)
                                    .font(.subheadline.bold())
                                Text(sws.stimulatorStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                Text("+\(sws.slowWaveEnhancementPercent)% Slow-Wave Amplitude")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 14) {
                            HStack(spacing: 8) {
                                Image(systemName: "bolt.heart.fill")
                                    .foregroundColor(.purple)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(sws.slowWaveBurstsDeliveredTonight) Bursts Delivered")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Phase-locked to 0.8Hz delta crests")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Image(systemName: "hourglass")
                                    .foregroundColor(.teal)
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("\(sws.deepSleepDurationMinutes) mins Deep SWS")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Memory consolidation active")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                // 2. Positional Obstructive Sleep Apnea (POSA) & Supine Rotational Nudge
                SleepCard(
                    title: "Positional Apnea (POSA) & Supine Rotational Nudge",
                    subtitle: "Detects airway collapse risk when sleeping flat on back (supine) and delivers a subtle directional chime to prompt rolling to the side.",
                    icon: "bed.double.fill",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Image(systemName: posa.currentPosition.icon)
                                        .foregroundColor(posa.currentPosition.color)
                                    Text(posa.currentPosition.rawValue)
                                        .font(.subheadline.bold())
                                }
                                Text(posa.positionStatusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button("Test Nudge") {
                                posa.triggerManualNudgeTest()
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Supine Duration Tonight")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text("\(posa.minutesInSupineTonight)")
                                        .font(.system(size: 20, weight: .bold, design: .rounded))
                                    Text("mins (\(String(format: "%.1f", posa.supinePercentage))%)")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Nudges Delivered")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Text("\(posa.rotationalNudgesDeliveredTonight) Side-Turn Nudges")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.blue)
                                Text("Last: \(posa.lastNudgeTimestamp)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(10)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                
                // 3. Hypnagogic Sleep-Onset Detection & Audio Fade-Out
                SleepCard(
                    title: "Hypnagogic Sleep-Onset Detection & Auto-Fade",
                    subtitle: "Senses kinetic stillness and respiratory deceleration to detect sleep onset, gracefully fading active media over 90 seconds.",
                    icon: "moon.fill",
                    accentColor: .indigo
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Status: \(hypnagogic.onsetStatusMessage)")
                                    .font(.subheadline.bold())
                                Text("Sleep Onset Latency: \(hypnagogic.sleepOnsetLatencyMinutes) minutes to fall asleep.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if hypnagogic.isUserAsleep {
                                Button("Reset Awake") {
                                    hypnagogic.resetAwakeState()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            } else {
                                Button("Simulate Onset") {
                                    hypnagogic.triggerManualSleepOnsetSimulation()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                        
                        // Volume Fade Bar
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text("Media Playback Volume")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.secondary)
                                Spacer()
                                Text("\(Int(hypnagogic.currentMediaFadeVolume * 100))%")
                                    .font(.system(size: 10, weight: .bold, design: .rounded))
                            }
                            ProgressView(value: hypnagogic.currentMediaFadeVolume, total: 1.0)
                                .progressViewStyle(.linear)
                                .tint(hypnagogic.isUserAsleep ? Color.indigo : Color.blue)
                        }
                    }
                }
                
                // 4. Circadian REM-Window "Dawn Simulation" Smart Alarm
                SleepCard(
                    title: "Circadian REM-Window \"Dawn Simulation\" Smart Alarm",
                    subtitle: "Targets light Stage 1 / REM sleep within a 20-minute window to wake you with ascending harmonic chimes, eliminating sleep inertia.",
                    icon: "sunrise.fill",
                    accentColor: .orange
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 6) {
                                    Text("Target Alarm: \(alarm.targetWakeTime)")
                                        .font(.subheadline.bold())
                                    Text("±\(alarm.wakeWindowMinutes)m Window")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.orange)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 2)
                                        .background(Color.orange.opacity(0.12))
                                        .clipShape(Capsule())
                                }
                                Text(alarm.smartAlarmStatus)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            if alarm.isAlarmTriggered {
                                Button("Dismiss Alarm") {
                                    alarm.dismissAlarm()
                                }
                                .buttonStyle(.borderedProminent)
                                .tint(.orange)
                                .controlSize(.small)
                            } else {
                                Button("Test Dawn Chime") {
                                    alarm.triggerTestAlarm()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                        
                        // 90-Min Sleep Architecture Indicator
                        HStack(spacing: 6) {
                            ForEach(1...5, id: \.self) { cycle in
                                VStack(spacing: 2) {
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(cycle == alarm.currentSleepCycle ? Color.orange : (cycle < alarm.currentSleepCycle ? Color.orange.opacity(0.4) : Color.primary.opacity(0.08)))
                                        .frame(height: 12)
                                    Text("C\(cycle)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                }
                
                // 5. Overnight Apnea-Hypopnea Index (AHI) & Snore Profiler
                SleepCard(
                    title: "Overnight Apnea-Hypopnea Index (AHI) & Snore Profiler",
                    subtitle: "Quantifies snoring intensity (dBA) and identifies thoracic respiratory pauses to calculate clinical AHI severity.",
                    icon: "stethoscope",
                    accentColor: .teal
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(String(format: "%.1f", apnea.estimatedAhiScore))
                                        .font(.system(size: 32, weight: .bold, design: .rounded))
                                        .foregroundColor(apnea.apneaSeverityCategory.color)
                                    Text("AHI / hr")
                                        .font(.subheadline.bold())
                                        .foregroundColor(.secondary)
                                }
                                Text(apnea.profilerSummary)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(apnea.apneaSeverityCategory.rawValue)
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(apnea.apneaSeverityCategory.color)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(apnea.apneaSeverityCategory.color.opacity(0.12))
                                    .clipShape(Capsule())
                                
                                Text("O2 Stability: \(apnea.oxygenStabilityPercent)%")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary)
                                
                                Button("Log Apnea Pause") {
                                    apnea.simulateApneaEvent()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.mini)
                            }
                        }
                        
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform")
                                    .foregroundColor(.teal)
                                Text("Current Snore: \(Int(apnea.currentSnoreDecibels)) dBA")
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            Spacer()
                            Text("Peak: \(Int(apnea.peakSnoreDecibelsTonight)) dBA • \(apnea.totalApneaEventsTonight) Total Pauses Tonight")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .padding(8)
                        .background(Color.primary.opacity(0.04))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                }
                
                // 6. Adaptive Bedroom Soundscape & Tinnitus Masker
                SleepCard(
                    title: "Adaptive Room Soundscape & Tinnitus Masker",
                    subtitle: "Dynamic ambient sound floor that elevates to mask outdoor traffic and includes a notch filter tuned to your audiogram.",
                    icon: "headphones",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle(soundscape.isSoundscapeActive ? "Soundscape Playing" : "Soundscape Off", isOn: $soundscape.isSoundscapeActive)
                                .toggleStyle(.switch)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Picker("Mode", selection: $soundscape.selectedSoundscape) {
                                ForEach(AdaptiveNightSoundscapeEngine.SoundscapeMode.allCases) { mode in
                                    Text(mode.rawValue).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .fixedSize()
                        }
                        
                        HStack(spacing: 12) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Adaptive Gain: \(Int(soundscape.currentOutputVolume * 100))%")
                                    .font(.system(size: 11, weight: .semibold))
                                Text("Auto-adjusts to room noise floor (\(Int(soundscape.ambientNoiseRoomFloorDba)) dBA)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "shield.fill")
                                    .font(.caption2)
                                Text("Notch: \(soundscape.notchFilterFrequencyHz)Hz")
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
                
                // 8. Adaptive Sleep Duty-Cycle (8+ Hour Battery Preservation)
                SleepCard(
                    title: "Adaptive Battery Preservation & Duty-Cycle (8+ Hour Sleep)",
                    subtitle: "Throttles IMU telemetry down to 2Hz during Stage 2/3 NREM sleep, saving 68% battery to last an entire 8-hour sleep cycle.",
                    icon: "battery.100.bolt",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Toggle("Enable Adaptive Sleep Duty-Cycle", isOn: $dutyCycle.batteryPreservationMode)
                                    .toggleStyle(.switch)
                                    .font(.subheadline.bold())
                                Text(dutyCycle.statusMessage)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 6) {
                                Image(systemName: "leaf.fill")
                                Text("\(dutyCycle.powerSavingsPercent)% Power Saved")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.green)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.green.opacity(0.12))
                            .clipShape(Capsule())
                        }
                        
                        HStack(spacing: 16) {
                            HStack(spacing: 8) {
                                Image(systemName: "gauge.with.dots.needle.33percent")
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 1) {
                                    Text("\(String(format: "%.1f", dutyCycle.currentSamplingRateHz)) Hz Sampling")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Burst downsampled during sleep")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 8) {
                                Image(systemName: "clock.badge.checkmark.fill")
                                    .foregroundColor(.teal)
                                VStack(alignment: .trailing, spacing: 1) {
                                    Text("~10h Runtime")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Full night coverage guaranteed")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

// Reusable Apple Glass Sleep Card
struct SleepCard<Content: View>: View {
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
