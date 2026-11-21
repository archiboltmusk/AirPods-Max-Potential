import Foundation

public enum PostureProfile: String, CaseIterable, Identifiable, Codable {
    case standardDesk = "Standard Desk"
    case readingPaperwork = "Reading & Paperwork"
    case standingDesk = "Standing Desk"
    case relaxedRecline = "Relaxed Recline"
    
    public var id: String { rawValue }
    
    public var icon: String {
        switch self {
        case .standardDesk: return "desktopcomputer"
        case .readingPaperwork: return "book.closed"
        case .standingDesk: return "figure.stand"
        case .relaxedRecline: return "chair.lounge"
        }
    }
    
    public var description: String {
        switch self {
        case .standardDesk:
            return "Optimized for laptop or desktop monitor typing with 12° forward tolerance."
        case .readingPaperwork:
            return "Relaxed 24° forward tolerance for looking down at notebooks, books, or desk documents."
        case .standingDesk:
            return "Strict 10° pitch tolerance to maintain upright cervical alignment while standing."
        case .relaxedRecline:
            return "Compensates for leaning back in office chairs during lectures or video watching."
        }
    }
    
    public var defaultPitchThreshold: Double {
        switch self {
        case .standardDesk: return 12.0
        case .readingPaperwork: return 24.0
        case .standingDesk: return 10.0
        case .relaxedRecline: return 20.0
        }
    }
    
    public var defaultRollThreshold: Double {
        switch self {
        case .standardDesk: return 10.0
        case .readingPaperwork: return 14.0
        case .standingDesk: return 8.0
        case .relaxedRecline: return 12.0
        }
    }
}
