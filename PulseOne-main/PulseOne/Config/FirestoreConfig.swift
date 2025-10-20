//
//  FirestoreConfig.swift
//  PulseOne
//
//  Centralized Firestore configuration
//

import Foundation

enum FirestoreConfig {

    // MARK: - Collection Names
    // Change these to match your Firestore database structure

    static let networkMetrics = "network_anomalies"  // Network data with anomaly detection
    static let sensorData = "sensor_data"            // Your sensor data collection
    static let anomalies = "anomalies"              // Your anomalies collection
    static let agentActions = "agent_actions"       // Your agent actions collection
    static let agentState = "agent_state"           // Your agent state collection

    // AI Request/Response collections for MCP communication
    static let aiRequests = "ai_requests"           // Requests from iOS app to MCP
    static let aiResponses = "ai_responses"         // Responses from MCP to iOS app

    // MARK: - Document Names

    static let agentStateCurrent = "current"        // Agent state document name

    // MARK: - Field Names
    // These match the CodingKeys in your models
    // Only change if your Firestore uses different field names

    struct Fields {
        // Common fields
        static let timestamp = "timestamp"
        static let deviceId = "device_id"

        // Network Metrics fields (network_anomalies collection)
        static let pingAvg = "ping_avg"
        static let pingJitter = "ping_jitter"
        static let packetLoss = "packet_loss"
        static let wifiStrength = "wifi_strength"
        static let isAnomaly = "is_anomaly"
        static let category = "category"
        static let motionLevel = "motion_level"

        // System metrics
        static let cpuLoad = "cpu_load"
        static let cpuTemp = "cpu_temp"
        static let ambientTemp = "ambient_temp"
        static let humidity = "humidity"

        // Network traffic
        static let bytesRecv = "bytes_recv"
        static let bytesSent = "bytes_sent"

        // Motion sensors
        static let ax = "ax"
        static let ay = "ay"
        static let az = "az"
        static let gx = "gx"
        static let gy = "gy"
        static let gz = "gz"

        // Sensor Data fields
        static let sensorType = "sensor_type"
        static let value = "value"
        static let unit = "unit"
        static let arduinoId = "arduino_id"

        // Anomaly fields
        static let type = "type"
        static let severity = "severity"
        static let description = "description"
        static let rootCause = "root_cause"
        static let recommendedAction = "recommended_action"
        static let isResolved = "is_resolved"
        static let resolvedAt = "resolved_at"
        static let affectedMetrics = "affected_metrics"

        // Agent Action fields
        static let actionType = "action_type"
        static let success = "success"
        static let anomalyId = "anomaly_id"
        static let beforeMetrics = "before_metrics"
        static let afterMetrics = "after_metrics"
        static let aiResponse = "ai_response"

        // AI Request/Response fields
        static let requestType = "request_type"
        static let status = "status"
        static let prompt = "prompt"
        static let context = "context"
        static let requestId = "request_id"
        static let responseId = "response_id"
        static let processedAt = "processed_at"
        static let completedAt = "completed_at"
        static let expiresAt = "expires_at"
        static let retryCount = "retry_count"
        static let response = "response"
        static let confidence = "confidence"
        static let suggestions = "suggestions"
        static let metadata = "metadata"
        static let error = "error"
    }

    // MARK: - Default Values

    #if DEBUG
    static let defaultDeviceId = "raspberry_pi_dev"     // Development device
    #else
    static let defaultDeviceId = "raspberry_pi_001"     // Production device
    #endif

    // MARK: - Query Limits

    static let defaultFetchLimit = 100
    static let defaultListenerLimit = 50
    static let agentActionsLimit = 50

    // MARK: - AI Request Settings

    static let aiRequestTimeout = 60.0              // Seconds to wait for AI response
    static let aiRequestExpirationMinutes = 10      // Minutes before request expires
    static let aiMaxRetries = 3                     // Maximum retry attempts
}

// MARK: - Usage Example
/*

 In FirestoreService.swift, replace hardcoded strings with:

 Before:
 db.collection("network_metrics")

 After:
 db.collection(FirestoreConfig.networkMetrics)

 Before:
 .whereField("device_id", isEqualTo: deviceId)

 After:
 .whereField(FirestoreConfig.Fields.deviceId, isEqualTo: deviceId)

 */
