import Foundation
#if canImport(HealthKit)
import HealthKit

/// Apple HealthKit Sync Engine for AirPodsIQ.
/// Automatically logs ergonomic focus sessions as Mindful Sessions and Mobility data.
@MainActor
public final class HealthKitPostureSync: ObservableObject {
    public static let shared = HealthKitPostureSync()
    
    private let healthStore = HKHealthStore()
    @Published public var isAuthorized: Bool = false
    @Published public var lastSyncDate: Date?
    @Published public var totalMindfulMinutesExported: Double = 0.0
    
    private init() {
        checkAuthorization()
    }
    
    public func requestAuthorization() async -> Bool {
        guard HKHealthStore.isHealthDataAvailable() else { return false }
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let typesToShare: Set<HKSampleType> = [mindfulType]
        let typesToRead: Set<HKObjectType> = [mindfulType]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            self.isAuthorized = true
            return true
        } catch {
            self.isAuthorized = false
            return false
        }
    }
    
    private func checkAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let status = healthStore.authorizationStatus(for: mindfulType)
        self.isAuthorized = (status == .sharingAuthorized)
    }
    
    public func recordPostureSession(startDate: Date, endDate: Date, averageScore: Int, slouchCount: Int) async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let mindfulType = HKObjectType.categoryType(forIdentifier: .mindfulSession)!
        let metadata: [String: Any] = [
            HKMetadataKeySyncVersion: 1,
            HKMetadataKeySyncIdentifier: UUID().uuidString,
            "AirPodsIQ_AverageScore": averageScore,
            "AirPodsIQ_SlouchCorrections": slouchCount,
            "AirPodsIQ_Hardware": "AirPods Headphone IMU"
        ]
        
        let sample = HKCategorySample(
            type: mindfulType,
            value: HKCategoryValue.notApplicable.rawValue,
            start: startDate,
            end: endDate,
            metadata: metadata
        )
        
        do {
            try await healthStore.save(sample)
            let sessionMinutes = endDate.timeIntervalSince(startDate) / 60.0
            self.totalMindfulMinutesExported += sessionMinutes
            self.lastSyncDate = Date()
        } catch {
            // Log local error
        }
    }
}
#endif
