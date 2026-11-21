import Foundation

/// Aggregated posture stats for a single calendar day.
public struct DayPostureStat: Codable, Identifiable {
    public let day: String // "yyyy-MM-dd"
    public var goodSeconds: Double
    public var badSeconds: Double
    public var slouches: Int
    public var sessions: Int

    public var id: String { day }
    public var totalSeconds: Double { goodSeconds + badSeconds }
    public var goodMinutes: Double { goodSeconds / 60.0 }
    public var badMinutes: Double { badSeconds / 60.0 }
    public var goodPercent: Double { totalSeconds > 0 ? (goodSeconds / totalSeconds) * 100.0 : 0.0 }

    private static let parser: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static let weekday: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f
    }()

    public var shortWeekday: String {
        guard let date = DayPostureStat.parser.date(from: day) else { return day }
        return DayPostureStat.weekday.string(from: date)
    }
}

/// 7-Day Rolling Posture Analytics and UserDefaults persistence.
/// Inspired by chandansgowda/posture-fix.
@MainActor
public final class RollingPostureHistoryStore: ObservableObject {
    public static let shared = RollingPostureHistoryStore()

    @Published public private(set) var days: [String: DayPostureStat] = [:]

    private let storageKey = "AirPodsPosture_7DayHistory"
    private let defaults = UserDefaults.standard

    private init() {
        load()
        seedSampleDataIfEmpty()
    }

    public static func dayKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    public func recordSession(goodSec: Double, badSec: Double, slouchCount: Int, date: Date = Date()) {
        let key = RollingPostureHistoryStore.dayKey(date)
        var stat = days[key] ?? DayPostureStat(day: key, goodSeconds: 0, badSeconds: 0, slouches: 0, sessions: 0)
        stat.goodSeconds += goodSec
        stat.badSeconds += badSec
        stat.slouches += slouchCount
        stat.sessions += 1
        days[key] = stat
        save()
    }

    public func lastDays(_ count: Int, now: Date = Date()) -> [DayPostureStat] {
        let calendar = Calendar.current
        var result: [DayPostureStat] = []
        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let date = calendar.date(byAdding: .day, value: -offset, to: now) else { continue }
            let key = RollingPostureHistoryStore.dayKey(date)
            result.append(days[key] ?? DayPostureStat(day: key, goodSeconds: 0, badSeconds: 0, slouches: 0, sessions: 0))
        }
        return result
    }

    public func clear() {
        days = [:]
        save()
    }

    private func load() {
        guard let data = defaults.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([String: DayPostureStat].self, from: data) else {
            return
        }
        days = decoded
    }

    private func save() {
        if let data = try? JSONEncoder().encode(days) {
            defaults.set(data, forKey: storageKey)
        }
    }

    private func seedSampleDataIfEmpty() {
        if days.isEmpty {
            let calendar = Calendar.current
            let now = Date()
            for offset in 1...6 {
                if let d = calendar.date(byAdding: .day, value: -offset, to: now) {
                    let key = RollingPostureHistoryStore.dayKey(d)
                    let good = Double.random(in: 180...320) * 60.0
                    let bad = Double.random(in: 20...65) * 60.0
                    let slouches = Int.random(in: 3...12)
                    days[key] = DayPostureStat(day: key, goodSeconds: good, badSeconds: bad, slouches: slouches, sessions: 4)
                }
            }
            // Today
            let todayKey = RollingPostureHistoryStore.dayKey(now)
            days[todayKey] = DayPostureStat(day: todayKey, goodSeconds: 145 * 60, badSeconds: 18 * 60, slouches: 4, sessions: 2)
            save()
        }
    }
}
