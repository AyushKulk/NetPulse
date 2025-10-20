//
//  AIAgentAction.swift
//  PulseOne
//
//  AI Agent action tracking
//

import Foundation
import FirebaseFirestore

enum AgentActionType: String, Codable {
    case diagnosticRun = "diagnostic_run"
    case networkRestart = "network_restart"
    case cacheFlush = "cache_flush"
    case configOptimization = "config_optimization"
    case alertGeneration = "alert_generation"
}

enum AgentStatus: String, Codable {
    case idle
    case analyzing
    case acting
    case waiting
}

struct AIAgentAction: Codable, Identifiable {
    @DocumentID var id: String?
    var timestamp: Date
    var actionType: AgentActionType
    var description: String
    var success: Bool
    var anomalyId: String?
    var beforeMetrics: [String: Double]?
    var afterMetrics: [String: Double]?
    var aiResponse: String?

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case actionType = "action_type"
        case description
        case success
        case anomalyId = "anomaly_id"
        case beforeMetrics = "before_metrics"
        case afterMetrics = "after_metrics"
        case aiResponse = "ai_response"
    }
}

struct AgentState: Codable {
    var status: AgentStatus
    var currentTask: String?
    var lastActionTimestamp: Date?
    var modelVersion: String
    var accuracyScore: Double?
}
