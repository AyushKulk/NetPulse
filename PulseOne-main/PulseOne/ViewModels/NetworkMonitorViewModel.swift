//
//  NetworkMonitorViewModel.swift
//  PulseOne
//

import Foundation
import Combine

@MainActor
class NetworkMonitorViewModel: ObservableObject {
    @Published var metricsHistory: [NetworkMetrics] = []
    @Published var selectedTimeRange: TimeRange = .oneHour
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let firestoreService = FirestoreService()

    enum TimeRange: String, CaseIterable {
        case oneHour = "1H"
        case sixHours = "6H"
        case oneDay = "24H"
        case sevenDays = "7D"

        var limit: Int {
            switch self {
            case .oneHour: return 60
            case .sixHours: return 360
            case .oneDay: return 1440
            case .sevenDays: return 2016
            }
        }
    }

    func loadMetrics() async {
        isLoading = true
        defer { isLoading = false }

        do {
            let allMetrics = try await firestoreService.fetchNetworkMetrics(limit: selectedTimeRange.limit)
            metricsHistory = allMetrics

            // Debug output
            print("📊 Loaded \(allMetrics.count) metrics")
            if let first = allMetrics.first {
                print("📊 First metric: ping=\(first.pingAvg), wifi=\(first.wifiStrength), category=\(first.category)")
            }
        } catch {
            errorMessage = error.localizedDescription
            print("❌ Error loading metrics: \(error.localizedDescription)")
        }
    }

    func startLiveUpdates() {
        firestoreService.listenToNetworkMetrics { [weak self] metrics in
            print("📡 Live update: \(metrics.count) metrics")
            self?.metricsHistory = metrics
        }
    }

    var averageLatency: Double {
        guard !metricsHistory.isEmpty else { return 0 }
        return metricsHistory.map(\.pingMs).reduce(0, +) / Double(metricsHistory.count)
    }

    var averagePacketLoss: Double {
        guard !metricsHistory.isEmpty else { return 0 }
        return metricsHistory.map(\.packetLossPercent).reduce(0, +) / Double(metricsHistory.count)
    }
}
