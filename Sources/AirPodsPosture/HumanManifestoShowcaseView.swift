import SwiftUI
import AppKit

/// HUMAN.md — The Biomechanical Manifesto.
/// Directly inspired by https://www.human-md.ai.
/// Celebrates the physical, human craftsmanship of posture, breathing, and presence
/// in an era of pure digital and AI creation.
public struct HumanManifestoShowcaseView: View {
    @ObservedObject var motion = MotionManager.shared
    @ObservedObject var respiratory = AcousticRespiratoryEngine.shared
    @ObservedObject var dualDirection = DualDirectionPosturalEngine.shared
    @AppStorage("appVisualTheme") var appVisualTheme: String = "humanCinema"
    
    @State private var selectedTenetIndex: Int = 0
    @State private var isPlayingAudioChime: Bool = false
    
    public struct ManifestoTenet: Identifiable {
        public let id: Int
        public let number: String
        public let headline: String
        public let subheadline: String
        public let prose: String
        public let tag: String
        public let icon: String
    }
    
    public let tenets: [ManifestoTenet] = [
        ManifestoTenet(
            id: 1,
            number: "01",
            headline: "break the chair on purpose",
            subheadline: "Symmetry is a rule. Rigid stillness is a trap. Break both.",
            prose: "Models are trained on averages, and modern chairs are designed for compliant statues. Your spine was forged for movement, hunting, breathing, and looking at the horizon. If you sit static for eight hours without shifting, you didn't conquer desk ergonomics—you surrendered to gravity. Stand up. Roll your shoulders. Stretch into the weird angles.",
            tag: "BIOMECHANICS",
            icon: "figure.walk.motion"
        ),
        ManifestoTenet(
            id: 2,
            number: "02",
            headline: "the machine has no cervical spine",
            subheadline: "Every prompt has an invisible body at the keyboard.",
            prose: "LLMs can synthesize poetry, generate software architectures, and pass licensing exams, but they do not possess a single cervical vertebra. They will never feel the dull burn at C7, the tight trapezii after a late-night commit, or the deep sigh of a diaphragm finally unclenching. Someone has to remind the screen that you exist. That's your job.",
            tag: "EMBODIMENT",
            icon: "brain.head.profile"
        ),
        ManifestoTenet(
            id: 3,
            number: "03",
            headline: "breath is the original biofeedback",
            subheadline: "Screen apnea is an unconscious surrender to pixel hypnosis.",
            prose: "When solving hard problems, humans unconsciously hold their breath for 20 to 45 seconds at a time. The brain starves for oxygen while processing tokens. Your AirPods Max acoustic sensors pick up the micro-vibrations of your chest wall. Listen to your lungs. Breathe with intention, not as an afterthought.",
            tag: "RESPIRATION",
            icon: "lungs.fill"
        ),
        ManifestoTenet(
            id: 4,
            number: "04",
            headline: "calibrate for truth, not vanity",
            subheadline: "The model conforms to the average. The human demands precision.",
            prose: "If you calibrate your baseline while slouching just to keep the badge green, you are gaslighting your own musculoskeletal system. Calibration is a covenant with reality. Sit tall, eyes level with the horizon, chin tucked, shoulders relaxed. Hold the true standard, then let the sensor keep you honest.",
            tag: "CALIBRATION",
            icon: "scope"
        ),
        ManifestoTenet(
            id: 5,
            number: "05",
            headline: "design for emotional resonance, not correctness",
            subheadline: "Correct posture is not a military brace; it is fluid life.",
            prose: "Tension, surprise, restraint, the pause before a breakthrough. These are not bugs in human anatomy. Fluid micro-adjustments are how the human organism distributes mechanical strain across all 24 articulating vertebrae. Don't be an immovable column. Be a bamboo reed in the wind.",
            tag: "FLUIDITY",
            icon: "water.waves"
        ),
        ManifestoTenet(
            id: 6,
            number: "06",
            headline: "seek delight, not delivery",
            subheadline: "If sitting at your Mac isn't joyful, why are we here?",
            prose: "Productivity decks talk about 'optimal ergonomics' and 'output throughput.' We talk about tactile clicks in your ear canal, glowing warm amber notch halos, and the satisfying chime of 10 neck repetitions done right. Make the feedback loop beautiful. Delight changes posture faster than guilt ever could.",
            tag: "JOY",
            icon: "sparkles"
        ),
        ManifestoTenet(
            id: 7,
            number: "07",
            headline: "own the physical machine. fully.",
            subheadline: "Your body is not a vehicle for carrying your head between meetings.",
            prose: "If you end the day feeling battered, the tools didn't fail you—you surrendered stewardship of your vessel. Sharpen yourself. Sharpen your physical boundaries. Guard your neck, guard your eyes, guard your breathing. The machines will keep getting faster. Only you can keep yourself human.",
            tag: "STEWARDSHIP",
            icon: "shield.checkered"
        )
    ]
    
    public init() {}
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 26) {
                // Editorial Manifesto Header
                manifestoHeader
                
                // Live Biomechanical Telemetry Filmstrip
                liveTelemetryFilmstrip
                
                // Featured Tenet Editorial Card Carousel
                tenetCarouselSection
                
                // Full Manifesto Index
                fullManifestoIndexSection
                
                // Footer Colophon
                manifestoFooter
            }
            .padding(.horizontal, 28)
            .padding(.vertical, 24)
        }
    }
    
    // MARK: - Header
    private var manifestoHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ANATOMICAL & PHILOSOPHICAL MANIFESTO · EDITION 2026")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                    .tracking(1.5)
                
                Spacer()
                
                // Theme Toggle Pill
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        appVisualTheme = (appVisualTheme == "humanCinema") ? "appleMinimal" : "humanCinema"
                    }
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: appVisualTheme == "humanCinema" ? "film.fill" : "sparkles")
                        Text(appVisualTheme == "humanCinema" ? "HUMAN.md Noir Active" : "Cupertino Theme")
                            .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule().fill(appVisualTheme == "humanCinema" ? HumanCinemaDesignSystem.Palette.vermilion.opacity(0.18) : Color.blue.opacity(0.15))
                    )
                    .foregroundColor(appVisualTheme == "humanCinema" ? HumanCinemaDesignSystem.Palette.vermilion : Color.blue)
                }
                .buttonStyle(.plain)
            }
            
            Text("HUMAN.md")
                .font(.system(size: 44, weight: .heavy, design: .serif))
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
            
            Text("> a working manifesto for posture, breathing, and presence in the age of machines.")
                .humanBlockquote()
            
            Text("A reminder, in plain text, of what humans actually bring to the table now that the machines are very good and getting better every day. The model has no spine. You do.")
                .font(.system(size: 13, design: .serif))
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.85))
                .lineSpacing(4)
                .frame(maxWidth: 680)
        }
    }
    
    // MARK: - Live Biomechanical Telemetry Filmstrip
    private var liveTelemetryFilmstrip: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("LIVE BIOMECHANICAL TELEMETRY")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                    .tracking(1.2)
                Spacer()
                HStack(spacing: 6) {
                    Circle()
                        .fill(motion.isConnected ? HumanCinemaDesignSystem.Palette.vermilion : Color.gray)
                        .frame(width: 7, height: 7)
                    Text(motion.isConnected ? "60Hz IMU STREAMING" : "OFFLINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(motion.isConnected ? HumanCinemaDesignSystem.Palette.vermilion : .secondary)
                }
            }
            
            HStack(spacing: 12) {
                // Metric 1: Posture Score
                TelemetryBadge(
                    title: "ALIGNMENT",
                    value: "\(motion.postureScore)%",
                    caption: motion.postureState.rawValue,
                    accentColor: motion.postureScore > 80 ? HumanCinemaDesignSystem.Palette.vermilion : .orange
                )
                
                // Metric 2: Cervical Pitch
                TelemetryBadge(
                    title: "CERVICAL PITCH",
                    value: String(format: "%+.0f°", motion.deltaPitch),
                    caption: motion.deltaPitch < -5 ? "Forward Lean" : "Level Horizon",
                    accentColor: HumanCinemaDesignSystem.Palette.emberAmber
                )
                
                // Metric 3: Lateral Roll
                TelemetryBadge(
                    title: "LATERAL TILT",
                    value: String(format: "%+.0f°", motion.deltaRoll),
                    caption: abs(motion.deltaRoll) < 4 ? "Bilateral Balance" : "Asymmetric",
                    accentColor: HumanCinemaDesignSystem.Palette.parchment
                )
                
                // Metric 4: Respiratory Rhythm
                TelemetryBadge(
                    title: "ACOUSTIC BREATH",
                    value: "\(respiratory.breathsPerMinute) BPM",
                    caption: respiratory.screenApneaDetected ? "Screen Apnea!" : "Eupneic Rhythm",
                    accentColor: respiratory.screenApneaDetected ? Color.red : HumanCinemaDesignSystem.Palette.vermilion
                )
            }
        }
        .padding(18)
        .humanFilmCard(borderGlow: HumanCinemaDesignSystem.Palette.vermilion.opacity(0.35))
    }
    
    // MARK: - Tenet Featured Card Carousel
    private var tenetCarouselSection: some View {
        let tenet = tenets[selectedTenetIndex]
        
        return VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("TENET \(tenet.number) OF \(String(format: "%02d", tenets.count))")
                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                    .tracking(1.2)
                
                Spacer()
                
                HStack(spacing: 8) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTenetIndex = (selectedTenetIndex - 1 + tenets.count) % tenets.count
                        }
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTenetIndex = (selectedTenetIndex + 1) % tenets.count
                        }
                    }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .bold))
                            .padding(6)
                            .background(Circle().fill(Color.white.opacity(0.08)))
                    }
                    .buttonStyle(.plain)
                }
            }
            
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("##")
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
                    Text(tenet.headline)
                        .font(.system(size: 26, weight: .bold, design: .serif))
                        .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                }
                
                Text(tenet.subheadline)
                    .font(.system(size: 14, design: .serif).italic())
                    .foregroundColor(HumanCinemaDesignSystem.Palette.emberAmber)
                
                Text(tenet.prose)
                    .font(.system(size: 13, design: .default))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.88))
                    .lineSpacing(5)
                    .padding(.top, 4)
            }
            .padding(22)
            .humanFilmCard(borderGlow: HumanCinemaDesignSystem.Palette.vermilion.opacity(0.35))
        }
    }
    
    // MARK: - Full Manifesto Index List
    private var fullManifestoIndexSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("INDEX · THE 7 PHYSICAL TENETS")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                .tracking(1.2)
            
            VStack(spacing: 8) {
                ForEach(tenets) { t in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selectedTenetIndex = t.id - 1
                        }
                    }) {
                        HStack(spacing: 14) {
                            Text(t.number)
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(selectedTenetIndex == (t.id - 1) ? HumanCinemaDesignSystem.Palette.vermilion : HumanCinemaDesignSystem.Palette.mutedSepia)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t.headline)
                                    .font(.system(size: 14, weight: selectedTenetIndex == (t.id - 1) ? .bold : .medium, design: .serif))
                                    .foregroundColor(HumanCinemaDesignSystem.Palette.parchment)
                                Text(t.subheadline)
                                    .font(.system(size: 11, design: .serif).italic())
                                    .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                            }
                            
                            Spacer()
                            
                            Text(t.tag)
                                .font(.system(size: 9, weight: .bold, design: .monospaced))
                                .padding(.horizontal, 7)
                                .padding(.vertical, 3)
                                .background(Capsule().fill(selectedTenetIndex == (t.id - 1) ? HumanCinemaDesignSystem.Palette.vermilion.opacity(0.2) : Color.white.opacity(0.06)))
                                .foregroundColor(selectedTenetIndex == (t.id - 1) ? HumanCinemaDesignSystem.Palette.vermilion : HumanCinemaDesignSystem.Palette.mutedSepia)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(selectedTenetIndex == (t.id - 1) ? HumanCinemaDesignSystem.Palette.charcoal.opacity(0.9) : Color.clear)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(12)
            .humanFilmCard(borderGlow: Color.white.opacity(0.06))
        }
    }
    
    // MARK: - Footer Colophon
    private var manifestoFooter: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()
                .background(HumanCinemaDesignSystem.Palette.charcoal)
            
            HStack {
                Text("CRAFTED FOR MAC · AIRPODS MAX & PRO SENSORS · ZERO TELEMETRY")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                Spacer()
                Text("HOMAGE TO HUMAN-MD.AI")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(HumanCinemaDesignSystem.Palette.vermilion)
            }
            .padding(.top, 4)
        }
    }
}

// MARK: - Subcomponent: Telemetry Badge
struct TelemetryBadge: View {
    let title: String
    let value: String
    let caption: String
    let accentColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.system(size: 9, weight: .bold, design: .monospaced))
                .foregroundColor(HumanCinemaDesignSystem.Palette.mutedSepia)
                .lineLimit(1)
            
            Text(value)
                .font(.system(size: 18, weight: .heavy, design: .serif))
                .foregroundColor(accentColor)
            
            Text(caption)
                .font(.system(size: 10, design: .serif).italic())
                .foregroundColor(HumanCinemaDesignSystem.Palette.parchment.opacity(0.75))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.black.opacity(0.35))
        .cornerRadius(10)
    }
}
