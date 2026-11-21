import SwiftUI
import Combine

public struct Obstacle: Identifiable {
    public let id = UUID()
    public var x: CGFloat
    public var gapY: CGFloat
    public var gapHeight: CGFloat = 130
}

@MainActor
public final class CervicalGameEngine: ObservableObject {
    public static let shared = CervicalGameEngine()
    
    @Published public var isPlaying: Bool = false
    @Published public var playerY: CGFloat = 180.0
    @Published public var score: Int = 0
    @Published public var highScore: Int = 0
    @Published public var gameOver: Bool = false
    @Published public var obstacles: [Obstacle] = []
    
    private var gameTimer: Timer?
    
    private init() {}
    
    public func startGame() {
        isPlaying = true
        gameOver = false
        score = 0
        playerY = 180.0
        obstacles.removeAll()
        spawnObstacle(x: 450)
        
        gameTimer?.invalidate()
        gameTimer = Timer.scheduledTimer(withTimeInterval: 0.033, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.gameTick()
            }
        }
    }
    
    public func stopGame() {
        isPlaying = false
        gameTimer?.invalidate()
        gameTimer = nil
    }
    
    public func updateHeadPitch(pitch: Double) {
        guard isPlaying && !gameOver else { return }
        
        // Map pitch: -25 deg (look down) to +25 deg (look up) -> playerY 320 to 40
        let targetY = CGFloat(180.0 - (pitch * 5.5))
        playerY = max(30.0, min(330.0, playerY * 0.75 + targetY * 0.25))
    }
    
    private func spawnObstacle(x: CGFloat) {
        let gap = CGFloat.random(in: 80...260)
        obstacles.append(Obstacle(x: x, gapY: gap))
    }
    
    private func gameTick() {
        guard isPlaying && !gameOver else { return }
        
        // Move obstacles left
        for i in 0..<obstacles.count {
            obstacles[i].x -= 4.0
        }
        
        // Score points
        for obs in obstacles {
            if obs.x < 80 && obs.x >= 76 {
                score += 1
                if score > highScore { highScore = score }
                MotionManager.shared.playFeedbackSound("Tink")
            }
        }
        
        // Check collisions (player is at X=80, size 30x30)
        for obs in obstacles {
            if obs.x > 50 && obs.x < 110 {
                let topObstacleBottom = obs.gapY - (obs.gapHeight / 2.0)
                let bottomObstacleTop = obs.gapY + (obs.gapHeight / 2.0)
                
                if playerY < topObstacleBottom || playerY > bottomObstacleTop {
                    gameOver = true
                    MotionManager.shared.playFeedbackSound("Basso")
                    break
                }
            }
        }
        
        // Remove off-screen obstacles and spawn new
        obstacles.removeAll { $0.x < -60 }
        if let last = obstacles.last, last.x < 240 {
            spawnObstacle(x: 460)
        }
    }
}

public struct CervicalFlappyGameView: View {
    @ObservedObject var game = CervicalGameEngine.shared
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("🎮 Cervical Flight: Neck ROM Warmup")
                        .font(.title3.bold())
                    Text("Gently tilt your head up and down to fly between the posture pillars. Stretches neck extensor muscles safely!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Text("Score: \(game.score) | Best: \(game.highScore)")
                    .font(.headline.monospaced())
            }
            
            ZStack {
                // Game Canvas
                RoundedRectangle(cornerRadius: 14)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.15), Color.cyan.opacity(0.10)], startPoint: .top, endPoint: .bottom))
                    .frame(height: 360)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
                    )
                
                // Obstacles
                ForEach(game.obstacles) { obs in
                    // Top pillar
                    Rectangle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: 44, height: max(0, obs.gapY - obs.gapHeight / 2.0))
                        .position(x: obs.x, y: (obs.gapY - obs.gapHeight / 2.0) / 2.0)
                    
                    // Bottom pillar
                    Rectangle()
                        .fill(Color.orange.opacity(0.8))
                        .frame(width: 44, height: max(0, 360.0 - (obs.gapY + obs.gapHeight / 2.0)))
                        .position(x: obs.x, y: (obs.gapY + obs.gapHeight / 2.0) + (360.0 - (obs.gapY + obs.gapHeight / 2.0)) / 2.0)
                }
                
                // Player Avatar (Head / AirPods)
                Circle()
                    .fill(Color.cyan)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Image(systemName: "headphones")
                            .foregroundColor(.white)
                            .font(.system(size: 16, weight: .bold))
                    )
                    .position(x: 80, y: game.playerY)
                    .shadow(color: .cyan.opacity(0.5), radius: 6)
                
                // Game Over Overlay
                if game.gameOver {
                    VStack(spacing: 12) {
                        Text("Session Complete!")
                            .font(.title2.bold())
                        Text("Final Score: \(game.score)")
                            .font(.headline)
                        Button("Fly Again") {
                            game.startGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(24)
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                } else if !game.isPlaying {
                    VStack(spacing: 12) {
                        Image(systemName: "figure.walk.motion")
                            .font(.system(size: 40))
                            .foregroundColor(.accentColor)
                        Text("Tilt Head Up/Down to Control Flight")
                            .font(.headline)
                        Button("Start 60s Neck Warmup") {
                            game.startGame()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            }
            .frame(height: 360)
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(14)
    }
}
