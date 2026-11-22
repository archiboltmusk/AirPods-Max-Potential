import Foundation
import AppKit
import PDFKit
import AirPodsCore

/// 1-Page Clinical Ergonomic & Cervical Mobility PDF Report Generator.
/// Generates a medical-grade vector PDF assessment formatted for physical therapists,
/// chiropractors, and orthopedic physicians using real AirPods IMU data.
@MainActor
public final class ClinicalPhysioReportExporter: ObservableObject {
    public static let shared = ClinicalPhysioReportExporter()
    
    @Published public var lastExportedPDFURL: URL?
    @Published public var isExporting: Bool = false
    
    private init() {}
    
    public func generateClinicalReportPDF() -> URL? {
        isExporting = true
        defer { isExporting = false }
        
        let pageWidth: CGFloat = 612.0  // Standard US Letter 8.5 x 11 inches
        let pageHeight: CGFloat = 792.0
        let pageRect = CGRect(x: 0, y: 0, width: pageWidth, height: pageHeight)
        
        let pdfData = NSMutableData()
        guard let consumer = CGDataConsumer(data: pdfData as CFMutableData),
              let context = CGContext(consumer: consumer, mediaBox: nil, nil) else {
            return nil
        }
        
        var mediaBox = pageRect
        context.beginPage(mediaBox: &mediaBox)
        
        // 1. Clean Hospital / Clinical Header Banner
        let headerRect = CGRect(x: 36, y: pageHeight - 90, width: pageWidth - 72, height: 54)
        context.setFillColor(CGColor(red: 0.12, green: 0.18, blue: 0.28, alpha: 1.0))
        context.fill(headerRect)
        
        let titleAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.boldSystemFont(ofSize: 16),
            .foregroundColor: NSColor.white
        ]
        let subAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 10),
            .foregroundColor: NSColor.lightGray
        ]
        
        let titleStr = NSAttributedString(string: "AirPodsIQ Clinical Cervical Spine & Ergonomic Assessment", attributes: titleAttributes)
        titleStr.draw(at: CGPoint(x: 48, y: pageHeight - 65))
        
        let subStr = NSAttributedString(string: "Hardware: AirPods Pro 6-Axis IMU (60Hz) • Clinical Reference: Kapandji Biomechanics", attributes: subAttributes)
        subStr.draw(at: CGPoint(x: 48, y: pageHeight - 80))
        
        // 2. Patient / User Summary Card
        let patientBox = CGRect(x: 36, y: pageHeight - 165, width: pageWidth - 72, height: 60)
        context.setStrokeColor(CGColor(gray: 0.8, alpha: 1.0))
        context.setLineWidth(1.0)
        context.stroke(patientBox)
        
        let bodyFont = NSFont.systemFont(ofSize: 10)
        let boldFont = NSFont.boldSystemFont(ofSize: 10)
        
        let nameStr = NSAttributedString(string: "Assessment Date: \(Date().formatted(date: .long, time: .shortened))", attributes: [.font: boldFont])
        nameStr.draw(at: CGPoint(x: 48, y: pageHeight - 125))
        
        let motion = MotionManager.shared
        let statsStr = NSAttributedString(
            string: "Overall Posture Score: \(motion.postureScore)% • Active Tracking: \(Int(motion.secondsTracked / 60)) min • Status: \(motion.postureState.rawValue)",
            attributes: [.font: bodyFont]
        )
        statsStr.draw(at: CGPoint(x: 48, y: pageHeight - 145))
        
        // 3. Cervical Disc Shear Force & Torque Section
        let torque = CervicalSpineTorqueEngine.shared
        let load = torque.currentLoad
        
        let torqueHeader = NSAttributedString(string: "Cervical Spine Torque & Biomechanical Disc Pressure (C1–C7)", attributes: [.font: NSFont.boldSystemFont(ofSize: 13)])
        torqueHeader.draw(at: CGPoint(x: 36, y: pageHeight - 195))
        
        let loadDetails = """
        • Current Effective Cervical Load: \(String(format: "%.1f", load.effectiveLoadLbs)) lbs (\(String(format: "%.1f", load.effectiveLoadKg)) kg)
        • Peak Shear Force Exerted Today: \(String(format: "%.1f", torque.peakLoadTodayLbs)) lbs
        • Cumulative Workday Torque: \(String(format: "%.0f", torque.cumulativeDayTorquePoundHours)) lb-hours
        • Ergonomic Risk Classification: \(load.discCompressionRisk.rawValue)
        """
        let loadAttr = NSAttributedString(string: loadDetails, attributes: [.font: bodyFont, .foregroundColor: NSColor.darkGray])
        loadAttr.draw(at: CGPoint(x: 48, y: pageHeight - 275))
        
        // 4. Overnight Sleep & Asymmetry Metrics
        let sleep = BilateralSleepPositionBalancer.shared
        let sleepHeader = NSAttributedString(string: "Overnight Bilateral Shoulder Sleep Symmetry", attributes: [.font: NSFont.boldSystemFont(ofSize: 13)])
        sleepHeader.draw(at: CGPoint(x: 36, y: pageHeight - 310))
        
        let sleepDetails = """
        • Left Lateral Sleep Duration: \(sleep.leftLateralMinutes) min
        • Right Lateral Sleep Duration: \(sleep.rightLateralMinutes) min
        • Supine (Back) Sleep Duration: \(sleep.supineMinutes) min
        • Asymmetry Shoulder Strain Index: \(sleep.shoulderAsymmetryRiskIndex)%
        • Clinical Morning Cross-Body Mobility Advice: \(sleep.morningRecommendation)
        """
        let sleepAttr = NSAttributedString(string: sleepDetails, attributes: [.font: bodyFont, .foregroundColor: NSColor.darkGray])
        sleepAttr.draw(at: CGPoint(x: 48, y: pageHeight - 390))
        
        // 5. Clinician / Physiotherapist Notes Section
        let notesHeader = NSAttributedString(string: "Physiotherapy & Ergonomic Plan Recommendations", attributes: [.font: NSFont.boldSystemFont(ofSize: 13)])
        notesHeader.draw(at: CGPoint(x: 36, y: pageHeight - 430))
        
        let notesBox = CGRect(x: 36, y: pageHeight - 560, width: pageWidth - 72, height: 110)
        context.setFillColor(CGColor(gray: 0.96, alpha: 1.0))
        context.fill(notesBox)
        context.stroke(notesBox)
        
        let notesText = """
        Prescription & Corrective Mobility Protocol:
        [  ] Perform 5x Chin Tucks every 90 minutes to decompress C5–C7 cervical facet joints.
        [  ] Adjust desk display height: elevate monitor so eye-level aligns with top 1/3 of panel.
        [  ] Balance lateral sleep duration to mitigate unilateral rotator cuff impingement.
        [  ] Continue daily tracking via AirPods TrueNorth Gravitational Horizon calibrator.
        """
        let notesAttr = NSAttributedString(string: notesText, attributes: [.font: bodyFont, .foregroundColor: NSColor.black])
        notesAttr.draw(at: CGPoint(x: 48, y: pageHeight - 545))
        
        // Signature Line
        let signStr = NSAttributedString(string: "Physician / Physical Therapist Signature: ___________________________________   Date: _________", attributes: [.font: bodyFont])
        signStr.draw(at: CGPoint(x: 36, y: pageHeight - 610))
        
        context.endPage()
        context.closePDF()
        
        // Write to Desktop
        let desktopURL = FileManager.default.urls(for: .desktopDirectory, in: .userDomainMask).first!
        let outputURL = desktopURL.appendingPathComponent("AirPodsIQ_Clinical_Report.pdf")
        
        pdfData.write(to: outputURL, atomically: true)
        self.lastExportedPDFURL = outputURL
        
        // Open PDF in default viewer
        NSWorkspace.shared.open(outputURL)
        return outputURL
    }
}
