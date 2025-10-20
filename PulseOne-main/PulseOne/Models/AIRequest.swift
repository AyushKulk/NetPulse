//
//  AIRequest.swift
//  PulseOne
//
//  Firestore-based AI request/response models for MCP communication
//

import Foundation
import FirebaseFirestore


/// Status of an AI request
enum AIRequestStatus: String, Codable {
    case pending    // Request created, waiting for MCP to pick up
    case processing // MCP is processing the request
    case completed  // MCP has responded
    case failed     // Request failed
    case timeout    // Request timed out
}

/// Type of AI request
enum AIRequestType: String, Codable {
    case analyzeAnomaly = "analyze_anomaly"
    case suggestHealing = "suggest_healing"
    case analyzeCorrelations = "analyze_correlations"
    case generalQuery = "general_query"
    case diagnosticAnalysis = "diagnostic_analysis"
}

/// AI Request sent from iOS app to MCP via Firestore
struct AIRequest: Codable, Identifiable {
    @DocumentID var id: String?

    // Request metadata
    var timestamp: Timestamp
    var requestType: AIRequestType
    var status: AIRequestStatus
    var deviceId: String

    // Request content
    var prompt: String
    var context: [String: String]? // Simple string dictionary for Firestore

    // Response tracking
    var responseId: String?      // Links to AIResponse document
    var processedAt: Timestamp?  // When MCP picked up request
    var completedAt: Timestamp?  // When MCP completed request

    // Timeout/retry logic
    var expiresAt: Timestamp     // Auto-delete old requests
    var retryCount: Int

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case requestType = "request_type"
        case status
        case deviceId = "device_id"
        case prompt
        case context
        case responseId = "response_id"
        case processedAt = "processed_at"
        case completedAt = "completed_at"
        case expiresAt = "expires_at"
        case retryCount = "retry_count"
    }
    
    // Explicit memberwise initializer because custom Decodable init removes synthesized one
    init(
        id: String? = nil,
        timestamp: Timestamp,
        requestType: AIRequestType,
        status: AIRequestStatus,
        deviceId: String,
        prompt: String,
        context: [String: String]? = nil,
        responseId: String? = nil,
        processedAt: Timestamp? = nil,
        completedAt: Timestamp? = nil,
        expiresAt: Timestamp,
        retryCount: Int
    ) {
        self.id = id
        self.timestamp = timestamp
        self.requestType = requestType
        self.status = status
        self.deviceId = deviceId
        self.prompt = prompt
        self.context = context
        self.responseId = responseId
        self.processedAt = processedAt
        self.completedAt = completedAt
        self.expiresAt = expiresAt
        self.retryCount = retryCount
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        do {
            self.id = try container.decodeIfPresent(String.self, forKey: .id)
            self.timestamp = try container.decode(Timestamp.self, forKey: .timestamp)
            self.requestType = try container.decode(AIRequestType.self, forKey: .requestType)
            self.status = try container.decode(AIRequestStatus.self, forKey: .status)
            self.deviceId = try container.decode(String.self, forKey: .deviceId)
            self.prompt = try container.decode(String.self, forKey: .prompt)
            self.context = try container.decodeIfPresent([String: String].self, forKey: .context)
            self.responseId = try container.decodeIfPresent(String.self, forKey: .responseId)
            self.processedAt = try container.decodeIfPresent(Timestamp.self, forKey: .processedAt)
            self.completedAt = try container.decodeIfPresent(Timestamp.self, forKey: .completedAt)
            self.expiresAt = try container.decode(Timestamp.self, forKey: .expiresAt)
            self.retryCount = try container.decode(Int.self, forKey: .retryCount)
        } catch {
            let path = container.codingPath.map { $0.stringValue }.joined(separator: ".")
            print("[AIRequest Decoding Error] path=\(path), error=\(error)")
            // Try to print raw values for easier debugging
            do {
                let raw = try JSONSerialization.jsonObject(with: JSONEncoder().encode(try container.decode([String: String?].self, forKey: .context)), options: [])
                print("[AIRequest Context Snapshot] \(raw)")
            } catch {
                // ignore
            }
            throw error
        }
    }

    // Helper to create a new request
    static func create(
        type: AIRequestType,
        prompt: String,
        deviceId: String = "iphone_app",
        expirationMinutes: Int = 10
    ) -> AIRequest {
        let now = Timestamp(date: Date())
        let expiration = Timestamp(date: Date().addingTimeInterval(TimeInterval(expirationMinutes * 60)))

        return AIRequest(
            timestamp: now,
            requestType: type,
            status: .pending,
            deviceId: deviceId,
            prompt: prompt,
            context: nil,
            responseId: nil,
            processedAt: nil,
            completedAt: nil,
            expiresAt: expiration,
            retryCount: 0
        )
    }
}

/// AI Response from MCP server
struct AIResponse: Codable, Identifiable {
    @DocumentID var id: String?

    // Response metadata
    var timestamp: Date  // Changed from Timestamp to Date for better compatibility
    var requestId: String        // Links back to AIRequest
    var deviceId: String

    // Response content
    var response: String         // Main AI response text
    var confidence: Double?      // Optional confidence score 0-1
    var suggestions: [String]?   // Optional list of suggestions
    var metadata: [String: String]? // Additional metadata from MCP

    // Error handling
    var error: String?
    var success: Bool

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case requestId = "request_id"
        case deviceId = "device_id"
        case response
        case confidence
        case suggestions
        case metadata
        case error
        case success
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        self.id = try container.decodeIfPresent(String.self, forKey: .id)

        // Flexible timestamp decoding - handle Timestamp, Date, String, or dict
        if let firestoreTimestamp = try? container.decode(Timestamp.self, forKey: .timestamp) {
            self.timestamp = firestoreTimestamp.dateValue()
        } else if let dateValue = try? container.decode(Date.self, forKey: .timestamp) {
            self.timestamp = dateValue
        } else if let stringValue = try? container.decode(String.self, forKey: .timestamp) {
            // Try ISO8601 string format
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            if let date = formatter.date(from: stringValue) {
                self.timestamp = date
            } else {
                // Try without fractional seconds
                formatter.formatOptions = [.withInternetDateTime]
                self.timestamp = formatter.date(from: stringValue) ?? Date()
            }
        } else if let doubleValue = try? container.decode(Double.self, forKey: .timestamp) {
            // Unix timestamp (seconds since 1970)
            self.timestamp = Date(timeIntervalSince1970: doubleValue)
        } else {
            // Fallback to current date
            print("⚠️ Warning: Could not decode timestamp, using current date")
            self.timestamp = Date()
        }

        self.requestId = try container.decode(String.self, forKey: .requestId)
        self.deviceId = try container.decode(String.self, forKey: .deviceId)

        // Flexible response decoding - handle string or empty
        self.response = (try? container.decode(String.self, forKey: .response)) ?? ""

        // Flexible confidence - handle Double, Int, or String
        if let doubleConfidence = try? container.decode(Double.self, forKey: .confidence) {
            self.confidence = doubleConfidence
        } else if let intConfidence = try? container.decode(Int.self, forKey: .confidence) {
            self.confidence = Double(intConfidence)
        } else if let stringConfidence = try? container.decode(String.self, forKey: .confidence),
                  let parsedConfidence = Double(stringConfidence) {
            self.confidence = parsedConfidence
        } else {
            self.confidence = nil
        }

        // Suggestions - handle array or null
        self.suggestions = try? container.decodeIfPresent([String].self, forKey: .suggestions)

        // Metadata - be flexible with types
        if let stringMeta = try? container.decodeIfPresent([String: String].self, forKey: .metadata) {
            self.metadata = stringMeta
        } else if let codableMeta = try? container.decodeIfPresent([String: CodableValue].self, forKey: .metadata) {
            // Convert CodableValue to String representations
            self.metadata = codableMeta.mapValues { value in
                switch value {
                case .string(let s): return s
                case .number(let n): return String(n)
                case .bool(let b): return String(b)
                case .null: return "null"
                case .array(let arr): return "[" + arr.map { v in
                    switch v {
                    case .string(let s): return s
                    case .number(let n): return String(n)
                    case .bool(let b): return String(b)
                    case .null: return "null"
                    case .array: return "array"
                    case .object: return "object"
                    }
                }.joined(separator: ", ") + "]"
                case .object(let obj): return "{" + obj.map { "\($0): \($1)" }.joined(separator: ", ") + "}"
                }
            }
        } else {
            self.metadata = nil
        }

        // Error - handle string or null
        self.error = try? container.decodeIfPresent(String.self, forKey: .error)

        // Success - handle Bool, Int (0/1), or String ("true"/"false")
        if let boolSuccess = try? container.decode(Bool.self, forKey: .success) {
            self.success = boolSuccess
        } else if let intSuccess = try? container.decode(Int.self, forKey: .success) {
            self.success = intSuccess != 0
        } else if let stringSuccess = try? container.decode(String.self, forKey: .success) {
            self.success = stringSuccess.lowercased() == "true" || stringSuccess == "1"
        } else {
            // Default to false if we can't decode it
            print("⚠️ Warning: Could not decode success field, defaulting to false")
            self.success = false
        }
    }
}

/// Helper for building prompts with context
struct AIPromptBuilder {

    static func buildAnomalyAnalysisPrompt(
        anomaly: Anomaly,
        metrics: NetworkMetrics?,
        sensorData: [SensorData]
    ) -> String {
        var prompt = """
        Analyze this network anomaly and provide insights:

        ANOMALY DETAILS:
        - Type: \(anomaly.type.rawValue)
        - Severity: \(anomaly.severity.rawValue)
        - Description: \(anomaly.description)
        """

        if let metrics = metrics {
            prompt += """


            CURRENT NETWORK METRICS:
            - Ping: \(metrics.pingAvg)ms
            - Jitter: \(metrics.pingJitter)ms
            - Packet Loss: \(metrics.packetLoss)%
            - WiFi Strength: \(metrics.wifiStrength)
            - CPU Load: \(metrics.cpuLoad)%
            - CPU Temp: \(metrics.cpuTemp)°C
            - Ambient Temp: \(metrics.ambientTemp)°C
            - Humidity: \(metrics.humidity)%
            - Motion Level: \(metrics.motionLevel)
            - Health Score: \(String(format: "%.1f", metrics.healthScore))/100
            - Category: \(metrics.category)
            """
        }

        if !sensorData.isEmpty {
            prompt += """


            SENSOR READINGS:
            \(summarizeSensorData(sensorData))
            """
        }

        prompt += """


        REQUIRED OUTPUT:
        1. Root cause analysis
        2. Correlation with environmental factors
        3. Impact assessment
        4. Recommended actions
        5. Prevention strategies
        """

        return prompt
    }

    static func buildHealingActionPrompt(anomaly: Anomaly) -> String {
        return """
        As a network healing AI agent, suggest specific actions for this issue:

        ISSUE:
        - Type: \(anomaly.type.rawValue)
        - Severity: \(anomaly.severity.rawValue)
        - Description: \(anomaly.description)

        CONTEXT:
        - Environment: Raspberry Pi with Arduino sensors
        - Network type: WiFi
        - Monitoring: Real-time anomaly detection system

        PROVIDE:
        1. Step-by-step healing actions
        2. Expected outcome for each action
        3. Risk assessment
        4. Rollback plan if needed
        5. Time estimate for resolution

        Be specific and actionable. Prioritize actions by impact.
        """
    }

    static func buildCorrelationAnalysisPrompt(
        networkMetrics: [NetworkMetrics],
        sensorData: [SensorData]
    ) -> String {
        let avgPing = networkMetrics.isEmpty ? 0 : networkMetrics.map(\.pingAvg).reduce(0, +) / Double(networkMetrics.count)
        let avgLoss = networkMetrics.isEmpty ? 0 : networkMetrics.map(\.packetLoss).reduce(0, +) / Double(networkMetrics.count)
        let avgJitter = networkMetrics.isEmpty ? 0 : networkMetrics.map(\.pingJitter).reduce(0, +) / Double(networkMetrics.count)

        return """
        Analyze correlations between network performance and environmental conditions:

        NETWORK PERFORMANCE SUMMARY (\(networkMetrics.count) data points):
        - Average Ping: \(String(format: "%.1f", avgPing))ms
        - Average Packet Loss: \(String(format: "%.2f", avgLoss))%
        - Average Jitter: \(String(format: "%.1f", avgJitter))ms

        ENVIRONMENTAL DATA:
        \(summarizeSensorData(sensorData))

        ANALYZE:
        1. Correlations between environmental factors and network performance
        2. Patterns that indicate degradation
        3. Optimal operating conditions
        4. Warning thresholds for environmental factors
        5. Predictive insights for future performance
        """
    }

    private static func summarizeSensorData(_ data: [SensorData]) -> String {
        let grouped = Dictionary(grouping: data, by: { $0.sensorType })
        return grouped.map { type, readings in
            let avg = readings.map(\.value).reduce(0, +) / Double(readings.count)
            let unit = readings.first?.unit ?? ""
            return "- \(type.rawValue): \(String(format: "%.2f", avg)) \(unit)"
        }.joined(separator: "\n")
    }
}

/// A Codable wrapper that can encode/decode simple JSON-like values used in Firestore.
/// Supports strings, numbers, booleans, null, arrays and dictionaries.
enum CodableValue: Codable {
    case string(String)
    case number(Double)
    case bool(Bool)
    case null
    case array([CodableValue])
    case object([String: CodableValue])

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            self = .null
        } else if let b = try? container.decode(Bool.self) {
            self = .bool(b)
        } else if let n = try? container.decode(Double.self) {
            self = .number(n)
        } else if let s = try? container.decode(String.self) {
            self = .string(s)
        } else if let arr = try? container.decode([CodableValue].self) {
            self = .array(arr)
        } else if let obj = try? container.decode([String: CodableValue].self) {
            self = .object(obj)
        } else {
            throw DecodingError.dataCorruptedError(in: container, debugDescription: "Unsupported value for CodableValue")
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .null:
            try container.encodeNil()
        case .bool(let b):
            try container.encode(b)
        case .number(let n):
            try container.encode(n)
        case .string(let s):
            try container.encode(s)
        case .array(let a):
            try container.encode(a)
        case .object(let o):
            try container.encode(o)
        }
    }
}

private struct AnyCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?
    init?(stringValue: String) { self.stringValue = stringValue; self.intValue = nil }
    init?(intValue: Int) { self.stringValue = "\(intValue)"; self.intValue = intValue }
}

