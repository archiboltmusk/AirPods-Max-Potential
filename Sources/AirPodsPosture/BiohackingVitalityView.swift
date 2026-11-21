import SwiftUI

public struct BiohackingVitalityView: View {
    @ObservedObject var sigh = PhysiologicalSighEngine.shared
    @ObservedObject var vor = VestibularReflexTrainerEngine.shared
    @ObservedObject var jpe = JointPositionErrorEngine.shared
    @ObservedObject var mastication = BilateralMasticationGuard.shared
    @ObservedObject var symptom = AcousticSymptomSentinel.shared
    @ObservedObject var circadian = CircadianMelatoninShield.shared
    @ObservedObject var vocal = VocalStrainCoach.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Header Bar (Apple Studio Style)
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.pink)
                        .frame(width: 40, height: 40)
                        .background(Color.pink.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Biohacking & Autonomic Vitality")
                            .font(.system(size: 20, weight: .bold))
                        Text("Huberman physiological sigh, VOR vision training, cervical JPE proprioception & circadian shielding")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 16)
                    
                    HStack(spacing: 8) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(sigh.currentStressIndex > 60 ? Color.orange : Color.green)
                                .frame(width: 7, height: 7)
                            Text("Stress: \(sigh.currentStressIndex)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.primary.opacity(0.06))
                        .clipShape(Capsule())
                    }
                    .fixedSize()
                }
                .padding(.bottom, 2)
                
                // 1. Physiological Sigh & Vagus Reset
                VitalityCard(
                    title: "Autonomous Physiological Sigh Vagus Reset",
                    subtitle: "Dr. Andrew Huberman's dual-inhale + long exhalation protocol to dump CO2 and collapse autonomic stress.",
                    icon: "wind",
                    accentColor: .teal
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Toggle("Auto-Trigger When Stress Spikes", isOn: $sigh.isAutonomousEnabled)
                                .toggleStyle(.switch)
                                .font(.subheadline.bold())
                            
                            Spacer()
                            
                            Text("\(sigh.sighsCompletedToday) Sighs Today")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.teal)
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(Color.teal.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        
                        if sigh.isSighActive {
                            HStack(spacing: 12) {
                                Image(systemName: "lungs.fill")
                                    .font(.title2)
                                    .foregroundColor(.teal)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(sigh.currentSighPhase.rawValue)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(.teal)
                                    Text("Follow the rhythmic chime: Inhale deep, quick top-up, then long sigh.")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Button("Cancel") {
                                    sigh.cancelSigh()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                            .padding(12)
                            .background(Color.teal.opacity(0.08))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            HStack {
                                Text("Dual inhale opens collapsed alveoli; slow exhalation slows sinoatrial heart rate node.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                Spacer(minLength: 12)
                                
                                Button(action: { sigh.triggerSigh() }) {
                                    Label("Trigger Sigh Reset", systemImage: "play.circle.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                // 2. Vestibular-Ocular Reflex (VOR) & Digital Brain Fog Eliminator
                VitalityCard(
                    title: "Vestibulo-Ocular Reflex (VOR) & Brain Fog Eliminator",
                    subtitle: "Synchronizes head motion with retinal stabilization to resolve suboccipital stiffness and afternoon eye strain.",
                    icon: "eye.circle.fill",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Training Axis", selection: $vor.currentAxis) {
                            ForEach(VestibularReflexTrainerEngine.TrainerAxis.allCases, id: \.self) { axis in
                                Text(axis == .horizontalYaw ? "Horizontal (Yaw)" : "Vertical (Pitch)").tag(axis)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(vor.isTrainerActive)
                        
                        Text(vor.currentAxis.cue)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if vor.isTrainerActive {
                            VStack(spacing: 10) {
                                HStack {
                                    Text("Time Remaining: \(vor.secondsRemaining)s")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    Spacer()
                                    Text("Current Sway: \(String(format: "%.1f°", vor.currentSwayAngle))")
                                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                        .foregroundColor(.blue)
                                }
                                
                                ProgressView(value: Double(45 - vor.secondsRemaining), total: 45.0)
                                    .tint(.blue)
                                
                                HStack {
                                    Button("End Session") {
                                        vor.completeSession()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                            .padding(10)
                            .background(Color.blue.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        } else {
                            HStack {
                                if vor.testCompleted {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Score: \(vor.vorFluidityScore)/100 • \(vor.stabilityRating)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(.green)
                                    }
                                } else {
                                    Text("Run a quick 45-second optokinetic reflex recalibration.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer(minLength: 12)
                                
                                Button(action: { vor.startSession(axis: vor.currentAxis) }) {
                                    Label(vor.testCompleted ? "Retest VOR" : "Start 45s VOR Test", systemImage: "bolt.heart.fill")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                // 3. Cervical Joint Position Error (JPE) Proprioceptive Diagnostic
                VitalityCard(
                    title: "Cervical Joint Position Error (JPE) Diagnostic",
                    subtitle: "Clinical PT gold standard: tests suboccipital mechanoreceptor accuracy and neck proprioceptive drift.",
                    icon: "scope",
                    accentColor: .orange
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(jpe.currentStep.rawValue)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)
                        
                        if jpe.isTestActive {
                            HStack(spacing: 10) {
                                switch jpe.currentStep {
                                case .step1CalibrateCenter:
                                    Button("Lock Neutral Baseline") {
                                        jpe.lockBaseline()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    
                                case .step2RotateLeft:
                                    Button("Turned Left & Returned: Lock Reposition") {
                                        jpe.lockLeftReposition()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    
                                case .step3RotateRight:
                                    Button("Turned Right & Returned: Complete Test") {
                                        jpe.lockRightReposition()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                    
                                case .step4Results:
                                    EmptyView()
                                }
                                
                                Button("Cancel") {
                                    jpe.cancelTest()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        } else {
                            HStack {
                                if jpe.testCompleted {
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Composite Error: \(String(format: "%.1f°", jpe.compositeErrorDegrees)) • \(jpe.proprioceptionGrade)")
                                            .font(.system(size: 12, weight: .bold))
                                            .foregroundColor(jpe.compositeErrorDegrees <= 3.5 ? .green : .orange)
                                        Text("Left Error: \(String(format: "%.1f°", jpe.leftErrorDegrees)) | Right Error: \(String(format: "%.1f°", jpe.rightErrorDegrees))")
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text("Close eyes and return to exact center to measure ligament mechanoreceptor accuracy.")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer(minLength: 12)
                                
                                Button(action: { jpe.startTest() }) {
                                    Label(jpe.testCompleted ? "Retest JPE" : "Start JPE Assessment", systemImage: "figure.walk")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                // 4. Bilateral Mastication Guard & 5. Acoustic Symptom Sentinel
                HStack(spacing: 16) {
                    // Mastication Card
                    VitalityCard(
                        title: "Bilateral Chewing Symmetry",
                        subtitle: "Balances jawline load to protect TMJ discs.",
                        icon: "mouth.fill",
                        accentColor: .purple
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("\(mastication.leftChewPercentage)% Left")
                                    .font(.system(size: 11, weight: .bold))
                                Spacer()
                                Text("\(mastication.rightChewPercentage)% Right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            
                            ProgressView(value: Double(mastication.leftChewPercentage), total: 100.0)
                                .tint(abs(mastication.leftChewPercentage - 50) > 20 ? .orange : .purple)
                            
                            if let alert = mastication.asymmetryWarningBanner {
                                Text(alert)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.orange)
                            } else {
                                Text(mastication.symmetryRating)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    // Symptom Sentinel Card
                    VitalityCard(
                        title: "Acoustic Symptom Sentinel",
                        subtitle: "Tracks dry coughs & throat clears passively.",
                        icon: "waveform.path.ecg",
                        accentColor: .red
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Coughs: \(symptom.coughBoutsToday)")
                                        .font(.system(size: 12, weight: .bold))
                                    Text("Clears: \(symptom.throatClearsToday)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Text("\(symptom.pulmonaryWellnessScore)% Wellness")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                                    .foregroundColor(.green)
                            }
                            
                            if let alert = symptom.airQualityAlertBanner {
                                Text(alert)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.orange)
                            } else {
                                Text("Passive on-device micro-acoustic sentinel active.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 6. Circadian Light & Melatonin Shield
                VitalityCard(
                    title: "Circadian Light & Melatonin Production Shield",
                    subtitle: "Integrates solar sunset timings with posture distance to prevent nighttime melatonin suppression.",
                    icon: "moon.stars.fill",
                    accentColor: .indigo
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(circadian.melatoninProtectionStatus)
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.indigo)
                                Text("Sunset: \(circadian.localSunsetTime) • Tighter posture threshold after dusk")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Button(action: { circadian.toggleWarmAcoustics() }) {
                                HStack(spacing: 4) {
                                    Image(systemName: circadian.isWarmAcousticEntrainmentActive ? "stop.fill" : "play.fill")
                                    Text(circadian.isWarmAcousticEntrainmentActive ? "Stop 432Hz" : "Play 432Hz Solfeggio")
                                }
                                .font(.system(size: 11, weight: .semibold))
                            }
                            .buttonStyle(.bordered)
                            .controlSize(.small)
                        }
                    }
                }
                
                // 7. Laryngeal Compression & Glottal Fry Coach
                VitalityCard(
                    title: "Laryngeal Speech Ergonomics & Glottal Fry Sentinel",
                    subtitle: "Protects vocal folds during Zoom/FaceTime meetings by flagging head slouching and laryngeal compression.",
                    icon: "waveform.circle.fill",
                    accentColor: .green
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Laryngeal Resonance: \(vocal.resonanceQuality)")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Continuous Speaking: \(vocal.continuousSpeakingMinutes) mins • Pitch \(Int(vocal.fundamentalFrequencyHz)) Hz")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            
                            Spacer()
                            
                            Text("Compression: \(vocal.laryngealCompressionPercent)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(vocal.laryngealCompressionPercent > 30 ? .orange : .green)
                        }
                        
                        ProgressView(value: Double(vocal.laryngealCompressionPercent), total: 100.0)
                            .tint(vocal.laryngealCompressionPercent > 30 ? .orange : .green)
                        
                        if let alert = vocal.vocalHydrationAlert {
                            Text(alert)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct VitalityCard<Content: View>: View {
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
