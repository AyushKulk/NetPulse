//
//  Anomaly.swift
//  PulseOne
//
//  Anomaly detection data model
//

import Foundation
import FirebaseFirestore

enum AnomalySeverity: String, Codable {
    case critical
    case warning
    case info

    var color: String {
        switch self {
        case .critical: return "red"
        case .warning: return "orange"
        case .info: return "blue"
        }
    }
}

enum AnomalyType: String, Codable {
    case latencySpike = "latency_spike"
    case packetLoss = "packet_loss"
    case temperatureAnomaly = "temperature_anomaly"
    case connectionDrop = "connection_drop"
    case hardwareIssue = "hardware_issue"
    case correlatedIssue = "correlated_issue"
}

struct Anomaly: Codable, Identifiable {
    @DocumentID var id: String?
    var timestamp: Date
    var type: AnomalyType
    var severity: AnomalySeverity
    var description: String
    var rootCause: String?
    var recommendedAction: String?
    var isResolved: Bool
    var resolvedAt: Date?
    var affectedMetrics: [String]
    var deviceId: String

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case type
        case severity
        case description
        case rootCause = "root_cause"
        case recommendedAction = "recommended_action"
        case isResolved = "is_resolved"
        case resolvedAt = "resolved_at"
        case affectedMetrics = "affected_metrics"
        case deviceId = "device_id"
    }
}
