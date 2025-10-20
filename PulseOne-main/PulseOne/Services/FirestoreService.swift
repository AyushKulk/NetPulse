//
//  FirestoreService.swift
//  PulseOne
//
//  Firestore data access layer
//

import Foundation
import FirebaseFirestore
import Combine

class FirestoreService: ObservableObject {
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []

    // MARK: - Network Metrics

    func fetchNetworkMetrics(deviceId: String = "", limit: Int = 100) async throws -> [NetworkMetrics] {
        // Fetching all network data from network_anomalies collection
        let snapshot = try await db.collection("network_anomalies")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents
            .compactMap { try? $0.data(as: NetworkMetrics.self) }
    }

    func listenToNetworkMetrics(deviceId: String = "", completion: @escaping ([NetworkMetrics]) -> Void) {
        // Real-time listener for network data from network_anomalies collection
        let listener = db.collection("network_anomalies")
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let metrics = documents
                    .compactMap { try? $0.data(as: NetworkMetrics.self) }
                completion(metrics)
            }
        listeners.append(listener)
    }

    // MARK: - Sensor Data

    func fetchSensorData(deviceId: String, sensorType: SensorType? = nil, limit: Int = 100) async throws -> [SensorData] {
        var query: Query = db.collection("sensor_data")
            .whereField("device_id", isEqualTo: deviceId)

        if let sensorType = sensorType {
            query = query.whereField("sensor_type", isEqualTo: sensorType.rawValue)
        }

        let snapshot = try await query
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: SensorData.self) }
    }

    func listenToSensorData(deviceId: String, completion: @escaping ([SensorData]) -> Void) {
        let listener = db.collection("sensor_data")
            .whereField("device_id", isEqualTo: deviceId)
            .order(by: "timestamp", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let data = documents.compactMap { try? $0.data(as: SensorData.self) }
                completion(data)
            }
        listeners.append(listener)
    }

    // MARK: - Anomalies

    func fetchAnomalies(deviceId: String, includeResolved: Bool = false) async throws -> [Anomaly] {
        var query: Query = db.collection("anomalies")
            .whereField("device_id", isEqualTo: deviceId)

        if !includeResolved {
            query = query.whereField("is_resolved", isEqualTo: false)
        }

        let snapshot = try await query
            .order(by: "timestamp", descending: true)
            .limit(to: 100)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Anomaly.self) }
    }

    func listenToAnomalies(deviceId: String, completion: @escaping ([Anomaly]) -> Void) {
        let listener = db.collection("anomalies")
            .whereField("device_id", isEqualTo: deviceId)
            .whereField("is_resolved", isEqualTo: false)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else { return }
                let anomalies = documents.compactMap { try? $0.data(as: Anomaly.self) }
                completion(anomalies)
            }
        listeners.append(listener)
    }

    func updateAnomaly(anomalyId: String, isResolved: Bool) async throws {
        try await db.collection("anomalies").document(anomalyId).updateData([
            "is_resolved": isResolved,
            "resolved_at": isResolved ? Timestamp(date: Date()) : FieldValue.delete()
        ])
    }

    // MARK: - AI Agent Actions

    func fetchAgentActions(limit: Int = 50) async throws -> [AIAgentAction] {
        let snapshot = try await db.collection("agent_actions")
            .order(by: "timestamp", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: AIAgentAction.self) }
    }

    func saveAgentAction(_ action: AIAgentAction) async throws {
        try db.collection("agent_actions").addDocument(from: action)
    }

    func listenToAgentState(completion: @escaping (AgentState?) -> Void) {
        let listener = db.collection("agent_state").document("current")
            .addSnapshotListener { snapshot, error in
                guard let data = snapshot?.data() else {
                    completion(nil)
                    return
                }
                let state = try? snapshot?.data(as: AgentState.self)
                completion(state)
            }
        listeners.append(listener)
    }

    // MARK: - AI Request/Response (MCP Communication via Firestore)

    /// Submit an AI request to Firestore for MCP to process
    func submitAIRequest(_ request: AIRequest) async throws -> String {
        let docRef = try db.collection(FirestoreConfig.aiRequests).addDocument(from: request)
        print("📤 AI Request submitted: \(docRef.documentID)")
        return docRef.documentID
    }

    /// Listen for AI response for a specific request
    func listenForAIResponse(requestId: String, timeout: TimeInterval = FirestoreConfig.aiRequestTimeout, completion: @escaping (Result<AIResponse, Error>) -> Void) {
        var hasResponded = false
        let timeoutTime = Date().addingTimeInterval(timeout)

        // Listen to the ai_responses collection for a response with matching request_id
        let listener = db.collection(FirestoreConfig.aiResponses)
            .whereField(FirestoreConfig.Fields.requestId, isEqualTo: requestId)
            .limit(to: 1)
            .addSnapshotListener { snapshot, error in
                guard !hasResponded else { return }

                if let error = error {
                    hasResponded = true
                    completion(.failure(error))
                    return
                }

                // Check for timeout
                if Date() > timeoutTime {
                    hasResponded = true
                    completion(.failure(NSError(domain: "AIRequest", code: -1, userInfo: [NSLocalizedDescriptionKey: "Request timed out"])))
                    return
                }

                guard let document = snapshot?.documents.first else {
                    // No response yet, keep listening
                    return
                }

                // Got a response!
                if let response = try? document.data(as: AIResponse.self) {
                    hasResponded = true
                    print("📥 AI Response received for request: \(requestId)")
                    completion(.success(response))
                } else {
                    hasResponded = true
                    completion(.failure(NSError(domain: "AIRequest", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode response"])))
                }
            }

        listeners.append(listener)

        // Also update the request status to show it's being monitored
        Task {
            try? await db.collection(FirestoreConfig.aiRequests).document(requestId).updateData([
                FirestoreConfig.Fields.status: AIRequestStatus.pending.rawValue
            ])
        }
    }

    /// Fetch AI response directly (if already completed)
    func fetchAIResponse(forRequestId requestId: String) async throws -> AIResponse? {
        let snapshot = try await db.collection(FirestoreConfig.aiResponses)
            .whereField(FirestoreConfig.Fields.requestId, isEqualTo: requestId)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { try? $0.data(as: AIResponse.self) }
    }

    /// Update AI request status (useful for retry logic)
    func updateAIRequestStatus(requestId: String, status: AIRequestStatus) async throws {
        try await db.collection(FirestoreConfig.aiRequests).document(requestId).updateData([
            FirestoreConfig.Fields.status: status.rawValue
        ])
    }

    /// Get pending AI requests (useful for debugging)
    func fetchPendingAIRequests() async throws -> [AIRequest] {
        let snapshot = try await db.collection(FirestoreConfig.aiRequests)
            .whereField(FirestoreConfig.Fields.status, isEqualTo: AIRequestStatus.pending.rawValue)
            .order(by: FirestoreConfig.Fields.timestamp, descending: true)
            .limit(to: 20)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: AIRequest.self) }
    }

    /// Clean up old/expired AI requests
    func cleanupExpiredAIRequests() async throws {
        let now = Timestamp(date: Date())
        let snapshot = try await db.collection(FirestoreConfig.aiRequests)
            .whereField(FirestoreConfig.Fields.expiresAt, isLessThan: now)
            .getDocuments()

        for document in snapshot.documents {
            try await document.reference.delete()
        }
        print("🧹 Cleaned up \(snapshot.documents.count) expired AI requests")
    }

    // MARK: - Cleanup

    func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }

    deinit {
        removeAllListeners()
    }
}
