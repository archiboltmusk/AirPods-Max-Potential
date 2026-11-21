import SwiftUI

public struct AdvancedUpgradesView: View {
    @ObservedObject var student = StudentStudySuiteEngine.shared
    @ObservedObject var spaces = SpatialSpacesManager.shared
    @ObservedObject var breathing = ResonanceBreathingCoach.shared
    @ObservedObject var binaural = BinauralBeatsEngine.shared
    @ObservedObject var drowsiness = DrowsinessGuard.shared
    @ObservedObject var appTracker = AppPostureCorrelationTracker.shared
    @ObservedObject var bonsai = ZenBonsaiDeskCompanion.shared
    @ObservedObject var preMeeting = PreMeetingPosturePrep.shared
    @ObservedObject var thoracic = ThoracicSlumpAnalyzer.shared
    @ObservedObject var scorecard = ScorecardExporter.shared
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header Bar (Apple Studio Style)
                HStack(alignment: .center, spacing: 14) {
                    Image(systemName: "wand.and.stars.inverse")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.purple)
                        .frame(width: 38, height: 38)
                        .background(Color.purple.opacity(0.14))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Spatial & Biometric Intelligence")
                            .font(.system(size: 20, weight: .bold))
                        Text("AirPods Pro 2 spatial canvas, vagus breathwork, drowsiness guard & study tools")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer(minLength: 16)
                    
                    // Scorecard Export Buttons with fixed width
                    HStack(spacing: 8) {
                        Button(action: { scorecard.copyToClipboard() }) {
                            Label("Copy", systemImage: "doc.on.doc")
                                .font(.system(size: 11, weight: .medium))
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button(action: { scorecard.saveToFile() }) {
                            Label("Export Report", systemImage: "square.and.arrow.down")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .fixedSize()
                }
                .padding(.bottom, 2)
                
                // 0. Student & Academic Study Hub
                AdvancedCard(
                    title: "Student & Academic Study Hub",
                    subtitle: "Hands-free Anki & slide gestures, 40Hz Gamma super-learning, and all-nighter sentry.",
                    icon: "graduationcap.fill",
                    accentColor: .purple
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        // Gesture Toggle & Status
                        HStack {
                            Toggle(isOn: $student.isHandsFreeStudyGesturesEnabled) {
                                HStack(spacing: 6) {
                                    Text("Hands-Free Flashcard & Lecture Slide Gestures")
                                        .font(.subheadline.bold())
                                    if student.isHandsFreeStudyGesturesEnabled {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 6, height: 6)
                                    }
                                }
                            }
                            .toggleStyle(.switch)
                            
                            Spacer()
                            
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.system(size: 9, weight: .bold))
                                Text("\(student.cardsFlippedCount) Flips")
                                    .font(.system(size: 11, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(.purple)
                            .padding(.horizontal, 9)
                            .padding(.vertical, 4)
                            .background(Color.purple.opacity(0.14))
                            .clipShape(Capsule())
                        }
                        
                        // 3-Column Apple Gesture Dock
                        HStack(spacing: 10) {
                            GestureActionPill(
                                icon: "arrow.down.to.line.compact",
                                gesture: "Nod Down",
                                keyCap: "Space",
                                action: "Flip Card / Next"
                            )
                            GestureActionPill(
                                icon: "arrow.right.circle.fill",
                                gesture: "Tilt Right",
                                keyCap: "→",
                                action: "Good / Advance"
                            )
                            GestureActionPill(
                                icon: "arrow.left.circle.fill",
                                gesture: "Tilt Left",
                                keyCap: "←",
                                action: "Again / Back"
                            )
                        }
                        
                        Text("Flip flashcards or advance lecture slides hands-free while taking notes with Apple Pencil.")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        
                        Divider().opacity(0.4)
                        
                        // Super-Learning Audio Engine
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Super-Learning Binaural Frequency:")
                                    .font(.system(size: 12, weight: .semibold))
                                Spacer()
                                Button(action: {
                                    student.toggleStudyAudio()
                                }) {
                                    HStack(spacing: 5) {
                                        Image(systemName: student.isStudyAudioPlaying ? "stop.fill" : "play.fill")
                                        Text(student.isStudyAudioPlaying ? "Stop Wave" : "Play Study Wave")
                                    }
                                    .font(.system(size: 11, weight: .bold))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 5)
                                    .background(student.isStudyAudioPlaying ? Color.red.opacity(0.15) : Color.purple.opacity(0.18))
                                    .foregroundColor(student.isStudyAudioPlaying ? .red : .purple)
                                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                            
                            // Short, elegant segmented control labels per Apple HIG
                            Picker("", selection: $student.selectedStudyFrequency) {
                                ForEach(StudentStudySuiteEngine.StudyWaveFrequency.allCases) { freq in
                                    Text(freq.shortTitle).tag(freq)
                                }
                            }
                            .pickerStyle(.segmented)
                            
                            // Subtitle explanatory callout
                            Text(student.selectedStudyFrequency.subtitle)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }
                        
                        Divider().opacity(0.4)
                        
                        // Micro-Sleep Guard
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("All-Nighter Micro-Sleep Guard")
                                    .font(.system(size: 12, weight: .semibold))
                                Text("Detects head-drop kinetic signatures when dozing off at your desk.")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $student.isCrammingModeActive)
                                .toggleStyle(.switch)
                        }
                        
                        if let alert = student.drowsinessAlertBanner {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(alert)
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.orange)
                            }
                            .padding(10)
                            .background(Color.orange.opacity(0.12))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        }
                    }
                }
                
                // 1. Spatial Virtual Desktops (Vision Pro Spaces Navigation)
                AdvancedCard(
                    title: "Spatial Virtual Desktops (Head-Turn Navigation)",
                    subtitle: "Turn head left or right to slide between macOS Spaces without touching keyboard or trackpad.",
                    icon: "macwindow.on.rectangle",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Toggle("Enable Head-Turn Spaces Navigation", isOn: $spaces.isEnabled)
                                .toggleStyle(.switch)
                            Spacer()
                            Text(spaces.lastSwitchedDirection)
                                .font(.caption.bold())
                                .foregroundColor(.blue)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(Color.blue.opacity(0.12))
                                .cornerRadius(6)
                        }
                        
                        if spaces.isEnabled {
                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Trigger Yaw Angle:")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text("\(Int(spaces.triggerAngleThreshold))°")
                                        .font(.caption2.bold())
                                }
                                Slider(value: $spaces.triggerAngleThreshold, in: 20.0...40.0, step: 1.0)
                                Text("Turn head past ±\(Int(spaces.triggerAngleThreshold))° to slide to the adjacent macOS Space.")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                // 2. Resonance Breathing & Vagus Nerve Coach
                AdvancedCard(
                    title: "Resonance Breathing & Vagus Nerve Reset",
                    subtitle: "Paced box breathing with expanding binaural soundscapes to reduce stress and improve HRV.",
                    icon: "lungs.fill",
                    accentColor: .teal
                ) {
                    VStack(alignment: .leading, spacing: 14) {
                        Picker("Pattern", selection: $breathing.selectedPattern) {
                            ForEach(BreathingPattern.allCases) { pattern in
                                Text(pattern.shortTitle).tag(pattern)
                            }
                        }
                        .pickerStyle(.segmented)
                        .disabled(breathing.isActive)
                        
                        if breathing.isActive {
                            VStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.teal.opacity(0.15))
                                        .frame(width: 140, height: 140)
                                        .scaleEffect(breathing.visualCircleScale)
                                        .animation(.easeInOut(duration: 0.2), value: breathing.visualCircleScale)
                                    
                                    VStack(spacing: 2) {
                                        Text(breathing.currentPhase.rawValue)
                                            .font(.headline.bold())
                                            .foregroundColor(.teal)
                                        Text(String(format: "%.1fs", breathing.secondsInCurrentPhase))
                                            .font(.system(.title3, design: .monospaced, weight: .bold))
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .frame(height: 150)
                                
                                HStack {
                                    Text("Completed Cycles: \(breathing.completedCycles)")
                                        .font(.caption.bold())
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button("End Breathing Session") {
                                        breathing.stopSession()
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.small)
                                }
                            }
                        } else {
                            HStack {
                                Text(breathing.selectedPattern.detailDescription)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer(minLength: 12)
                                Button("Start Breathwork") {
                                    breathing.startSession()
                                }
                                .buttonStyle(.borderedProminent)
                                .controlSize(.small)
                            }
                        }
                    }
                }
                
                // 3. 40 Hz Gamma & 10 Hz Alpha Binaural Beats Engine
                AdvancedCard(
                    title: "Neuro-Acoustic Binaural Beats Synthesizer",
                    subtitle: "True stereo sine waves with phase differences for cognitive entrainment and problem-solving.",
                    icon: "waveform.badge.magnifyingglass",
                    accentColor: .purple
                ) {
                    VStack(alignment: .leading, spacing: 12) {
                        Picker("Entrainment Preset", selection: $binaural.selectedPreset) {
                            ForEach(BinauralPreset.allCases) { preset in
                                Text(preset.rawValue).tag(preset)
                            }
                        }
                        .pickerStyle(.menu)
                        
                        HStack {
                            Text("Volume:")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Slider(value: $binaural.volume, in: 0.05...1.0, step: 0.05)
                                .frame(maxWidth: 160)
                            
                            Spacer()
                            
                            Button(action: {
                                if binaural.isPlaying {
                                    binaural.stop()
                                } else {
                                    binaural.start()
                                }
                            }) {
                                Label(
                                    binaural.isPlaying ? "Stop Binaural Beats" : "Play \(Int(binaural.selectedPreset.beatFrequency)) Hz Binaural Tone",
                                    systemImage: binaural.isPlaying ? "stop.fill" : "play.fill"
                                )
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }
                    }
                }
                
                // 4. Thoracic Slump vs Chin-Tilt Disambiguation
                AdvancedCard(
                    title: "Thoracic Spine vs Chin-Tilt Disambiguation",
                    subtitle: "Decomposes gravity vector to differentiate simple neck tilt from full torso spinal hunching.",
                    icon: "figure.walk",
                    accentColor: .orange
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Spinal State:")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(thoracic.slumpType.rawValue)
                                .font(.subheadline.bold())
                                .foregroundColor(thoracic.slumpType == .optimal ? .green : (thoracic.slumpType == .chinTiltOnly ? .orange : .red))
                        }
                        
                        Text(thoracic.correctiveCues)
                            .font(.caption)
                            .foregroundColor(.primary)
                            .padding(8)
                            .background(Color.primary.opacity(0.04))
                            .cornerRadius(6)
                    }
                }
                
                // 5. App-by-App Posture Heatmap
                AdvancedCard(
                    title: "App-by-App Ergonomic Posture Correlation",
                    subtitle: "Identifies which applications trigger your worst ergonomic slouching habits.",
                    icon: "chart.bar.xaxis",
                    accentColor: .indigo
                ) {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Active App: \(appTracker.currentAppName)")
                                .font(.caption.bold())
                                .foregroundColor(.accentColor)
                            Spacer()
                            Text("\(appTracker.stats.count) apps tracked")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        if appTracker.stats.isEmpty {
                            Text("Actively monitoring foreground apps...")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        } else {
                            VStack(spacing: 6) {
                                ForEach(appTracker.stats.prefix(5)) { stat in
                                    HStack {
                                        Text(stat.id)
                                            .font(.caption.bold())
                                            .frame(width: 110, alignment: .leading)
                                            .lineLimit(1)
                                        
                                        ProgressView(value: Double(stat.postureScore), total: 100.0)
                                            .tint(stat.postureScore > 80 ? .green : (stat.postureScore > 60 ? .orange : .red))
                                        
                                        Text("\(stat.postureScore)% Good")
                                            .font(.system(.caption, design: .monospaced, weight: .bold))
                                            .foregroundColor(stat.postureScore > 80 ? .green : .orange)
                                            .frame(width: 80, alignment: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
                
                // 6. Zen Bonsai Desk Companion & Drowsiness Guard
                HStack(spacing: 16) {
                    // Zen Bonsai Card
                    AdvancedCard(
                        title: "Zen Bonsai Companion",
                        subtitle: "Gamified posture desk companion.",
                        icon: "leaf.fill",
                        accentColor: .green
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: bonsai.treeIconName)
                                    .font(.title2)
                                    .foregroundColor(.green)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Bonsai Health: \(bonsai.healthPercentage)%")
                                        .font(.subheadline.bold())
                                    Text("Growth Level \(bonsai.growthLevel) • \(bonsai.statusMessage)")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            ProgressView(value: Double(bonsai.healthPercentage), total: 100.0)
                                .tint(.green)
                        }
                    }
                    
                    // Drowsiness Guard Card
                    AdvancedCard(
                        title: "Drowsiness Guard",
                        subtitle: "Nodding-off hypnic jerk sentry.",
                        icon: "powersleep",
                        accentColor: .red
                    ) {
                        VStack(alignment: .leading, spacing: 8) {
                            Toggle("Micro-Sleep Sentry", isOn: $drowsiness.isEnabled)
                                .toggleStyle(.switch)
                            
                            HStack {
                                Text("Incidents:")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                                Text("\(drowsiness.drowsinessIncidentCount)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(drowsiness.drowsinessIncidentCount > 0 ? .red : .green)
                                Spacer()
                                if let msg = drowsiness.alertMessage {
                                    Text(msg)
                                        .font(.system(size: 9))
                                        .foregroundColor(.red)
                                        .lineLimit(1)
                                }
                            }
                        }
                    }
                }
                
                // 7. Pre-Meeting Posture Prep
                AdvancedCard(
                    title: "Smart Pre-Meeting Posture Checklist",
                    subtitle: "30-second camera alignment & chest elevation checklist before video calls.",
                    icon: "video.badge.checkmark",
                    accentColor: .blue
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        if preMeeting.isPrepActive {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(preMeeting.prepSteps[preMeeting.prepStepIndex])
                                    .font(.headline)
                                    .foregroundColor(.accentColor)
                                
                                HStack {
                                    Text("Step \(preMeeting.prepStepIndex + 1) of \(preMeeting.prepSteps.count)")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Button(preMeeting.prepStepIndex + 1 == preMeeting.prepSteps.count ? "Done (Calibrate)" : "Next Step") {
                                        preMeeting.nextStep()
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .controlSize(.small)
                                }
                            }
                        } else {
                            HStack {
                                Text(preMeeting.checklistCompleted ? "Checklist completed & posture zeroed!" : "Run 30s camera level and chest alignment check before joining calls.")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                                Button("Start Pre-Meeting Check") {
                                    preMeeting.startPrep()
                                }
                                .buttonStyle(.bordered)
                                .controlSize(.small)
                            }
                        }
                    }
                }
            }
            .padding(20)
        }
    }
}

struct AdvancedCard<Content: View>: View {
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

struct GestureActionPill: View {
    let icon: String
    let gesture: String
    let keyCap: String
    let action: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.purple)
            
            VStack(alignment: .leading, spacing: 1) {
                HStack(spacing: 4) {
                    Text(gesture)
                        .font(.system(size: 11, weight: .bold))
                    Text(keyCap)
                        .font(.system(size: 9, weight: .heavy, design: .monospaced))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.primary.opacity(0.12))
                        .clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }
                Text(action)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.04))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
        )
    }
}
