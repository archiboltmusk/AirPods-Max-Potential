import SwiftUI

public struct StretchCoachView: View {
    @ObservedObject var coach = StretchCoach.shared
    @ObservedObject var motion: MotionManager
    
    public init(motion: MotionManager) {
        self.motion = motion
    }
    
    public var body: some View {
        VStack(spacing: 24) {
            if !coach.isActive && !coach.isCompleted {
                // Intro screen
                VStack(spacing: 16) {
                    Image(systemName: "figure.mind.and.body")
                        .font(.system(size: 54))
                        .foregroundColor(.blue)
                        .padding(.bottom, 8)
                    
                    Text("Interactive Cervical Mobility Routine")
                        .font(.title2.bold())
                    
                    Text("Combat desk slump and text-neck strain. This 2-minute routine uses your AirPods' motion sensors to measure each stretch angle and confirm proper execution.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 480)
                    
                    VStack(alignment: .leading, spacing: 10) {
                        ExerciseBullet(number: "1", text: "Ceiling Gaze (Counteracts forward head slouch)")
                        ExerciseBullet(number: "2", text: "Chin Tuck (Relieves suboccipital tension)")
                        ExerciseBullet(number: "3", text: "Lateral Flexions (Stretches tight trapezius muscles)")
                        ExerciseBullet(number: "4", text: "Rotational Mobility (Mobilizes cervical spine)")
                    }
                    .padding(16)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(12)
                    
                    Button(action: {
                        coach.startSession()
                    }) {
                        Label("Start Guided Stretches", systemImage: "play.fill")
                            .font(.headline)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 8)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
                .padding(30)
            } else if coach.isCompleted {
                // Completion screen
                VStack(spacing: 20) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 64))
                        .foregroundColor(.green)
                    
                    Text("Neck Mobility Session Complete!")
                        .font(.title.bold())
                    
                    Text("Great job resetting your cervical spine posture. Regular micro-breaks prevent cumulative strain and tension headaches.")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 460)
                    
                    HStack(spacing: 16) {
                        Button("Re-calibrate Posture") {
                            motion.calibrateCurrentPosture()
                        }
                        .buttonStyle(.bordered)
                        
                        Button("Done") {
                            coach.isCompleted = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding(40)
            } else if let exercise = coach.currentExercise {
                // Active exercise screen
                VStack(spacing: 20) {
                    // Header progress
                    HStack {
                        Text("Exercise \(coach.currentExerciseIndex + 1) of \(coach.exercises.count)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Button("Stop Routine") {
                            coach.stopSession()
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.secondary)
                    }
                    
                    // Current Exercise Title
                    VStack(spacing: 6) {
                        Label(exercise.title, systemImage: exercise.icon)
                            .font(.title2.bold())
                            .foregroundColor(.accentColor)
                        Text(exercise.subtitle)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    // Large Circular Target & Hold Progress Ring
                    ZStack {
                        // Background track
                        Circle()
                            .stroke(Color.primary.opacity(0.1), lineWidth: 16)
                            .frame(width: 180, height: 180)
                        
                        // Active progress ring
                        Circle()
                            .trim(from: 0, to: CGFloat(coach.currentHoldTime / exercise.holdDuration))
                            .stroke(
                                coach.isInTargetZone ? Color.green : Color.orange,
                                style: StrokeStyle(lineWidth: 16, lineCap: .round)
                            )
                            .frame(width: 180, height: 180)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: coach.currentHoldTime)
                        
                        VStack(spacing: 4) {
                            if coach.isInTargetZone {
                                Text("\(Int(ceil(exercise.holdDuration - coach.currentHoldTime)))s")
                                    .font(.system(size: 42, weight: .heavy, design: .rounded))
                                    .foregroundColor(.green)
                                Text("HOLD")
                                    .font(.caption.bold())
                                    .foregroundColor(.green)
                            } else {
                                Image(systemName: exercise.icon)
                                    .font(.system(size: 38))
                                    .foregroundColor(.orange)
                                Text("TARGET ZONE")
                                    .font(.caption2.bold())
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .frame(height: 200)
                    
                    // Instruction text
                    Text(exercise.instruction)
                        .font(.headline)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 420)
                    
                    // Live Axis Tracker Bar
                    let currentAngle = currentAngle(for: exercise)
                    HStack(spacing: 12) {
                        Text("Current Angle:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%+.1f°", currentAngle))
                            .font(.system(.body, design: .monospaced, weight: .bold))
                            .foregroundColor(coach.isInTargetZone ? .green : .orange)
                        
                        Text("(Goal: \(Int(exercise.minAngle))° to \(Int(exercise.maxAngle))°)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color(NSColor.controlBackgroundColor))
                    .cornerRadius(10)
                }
                .padding(24)
                .onReceive(motion.$deltaPitch) { _ in coach.update(motion: motion) }
                .onReceive(motion.$deltaRoll) { _ in coach.update(motion: motion) }
                .onReceive(motion.$deltaYaw) { _ in coach.update(motion: motion) }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
    
    private func currentAngle(for exercise: StretchExercise) -> Double {
        switch exercise.targetAxis {
        case .pitch: return motion.deltaPitch
        case .roll: return motion.deltaRoll
        case .yaw: return motion.deltaYaw
        }
    }
}

struct ExerciseBullet: View {
    let number: String
    let text: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Text(number)
                .font(.caption.bold())
                .frame(width: 20, height: 20)
                .background(Color.accentColor.opacity(0.15))
                .foregroundColor(.accentColor)
                .clipShape(Circle())
            
            Text(text)
                .font(.subheadline)
                .foregroundColor(.primary)
        }
    }
}
