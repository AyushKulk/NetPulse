//
//  DashboardViewModel.swift
//  PulseOne
//

import Foundation
import Combine

@MainActor
class DashboardViewModel: ObservableObject {
    @Published var latestMetrics: NetworkMetrics?
    @Published var activeAnomalies: [Anomaly] = []
    @Published var recentSensorData: [SensorData] = []
    @Published var healthScore: Double = 0
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService()
    private let deviceId = "raspberry_pi_001" // TODO:

    func startListening() {
        firestoreService.listenToNetworkMetrics { [weak self] metrics in
            print("📡 Dashboard: Received \(metrics.count) metrics")
            self?.latestMetrics = metrics.first
            self?.healthScore = metrics.first?.healthScore ?? 0
            if let first = metrics.first {
                print("📊 Latest metric: ping=\(first.pingMs), health=\(first.healthScore)")
            }
        }

        firestoreService.listenToAnomalies(deviceId: deviceId) { [weak self] anomalies in
            self?.activeAnomalies = anomalies
        }

        firestoreService.listenToSensorData(deviceId: deviceId) { [weak self] data in
            self?.recentSensorData = data
        }
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }

        do {
            async let metrics = firestoreService.fetchNetworkMetrics(limit: 1)
            async let anomalies = firestoreService.fetchAnomalies(deviceId: deviceId)
            async let sensors = firestoreService.fetchSensorData(deviceId: deviceId, limit: 20)

            let (m, a, s) = try await (metrics, anomalies, sensors)
            print("🔄 Refreshed: \(m.count) metrics, \(a.count) anomalies, \(s.count) sensors")
            latestMetrics = m.first
            healthScore = m.first?.healthScore ?? 0
            activeAnomalies = a
            recentSensorData = s
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Dashboard refresh error: \(error.localizedDescription)")
        }
    }

    func stopListening() {
        firestoreService.removeAllListeners()
    }
}
