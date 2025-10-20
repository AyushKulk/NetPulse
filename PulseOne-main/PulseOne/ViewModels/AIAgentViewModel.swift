//
//  AIAgentViewModel.swift
//  PulseOne
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
class AIAgentViewModel: ObservableObject {
    @Published var agentState: AgentState?
    @Published var recentActions: [AIAgentAction] = []
    @Published var isAnalyzing = false
    @Published var analysisResult: String?
    @Published var errorMessage: String?
    @Published var currentRequestId: String?  // Track the current AI request

    private let firestoreService = FirestoreService()

    func startListening() {
        firestoreService.listenToAgentState { [weak self] state in
            self?.agentState = state
        }

        Task {
            await loadRecentActions()
        }
    }

    func loadRecentActions() async {
        do {
            recentActions = try await firestoreService.fetchAgentActions(limit: 50)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func analyzeAnomaly(_ anomaly: Anomaly, metrics: NetworkMetrics?, sensorData: [SensorData]) async {
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil

        do {
            guard let metrics = metrics else {
                errorMessage = "No metrics available"
                isAnalyzing = false
                return
            }

            // Build prompt using helper
            let prompt = AIPromptBuilder.buildAnomalyAnalysisPrompt(
                anomaly: anomaly,
                metrics: metrics,
                sensorData: sensorData
            )

            // Create AI request
            let request = AIRequest.create(
                type: .analyzeAnomaly,
                prompt: prompt
            )

            // Submit to Firestore
            let requestId = try await firestoreService.submitAIRequest(request)
            currentRequestId = requestId

            // Listen for response
            await waitForAIResponse(requestId: requestId)

        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }

    func requestHealingAction(for anomaly: Anomaly) async {
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil

        do {
            // Build prompt using helper
            let prompt = AIPromptBuilder.buildHealingActionPrompt(anomaly: anomaly)

            // Create AI request
            let request = AIRequest.create(
                type: .suggestHealing,
                prompt: prompt
            )

            // Submit to Firestore
            let requestId = try await firestoreService.submitAIRequest(request)
            currentRequestId = requestId

            // Listen for response
            await waitForAIResponse(requestId: requestId)

        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }

    func analyzeCorrelations(metrics: [NetworkMetrics], sensors: [SensorData]) async {
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil

        do {
            // Build prompt using helper
            let prompt = AIPromptBuilder.buildCorrelationAnalysisPrompt(
                networkMetrics: metrics,
                sensorData: sensors
            )

            // Create AI request
            let request = AIRequest.create(
                type: .analyzeCorrelations,
                prompt: prompt
            )

            // Submit to Firestore
            let requestId = try await firestoreService.submitAIRequest(request)
            currentRequestId = requestId

            // Listen for response
            await waitForAIResponse(requestId: requestId)

        } catch {
            errorMessage = error.localizedDescription
            isAnalyzing = false
        }
    }

    // MARK: - Private Methods

    private func waitForAIResponse(requestId: String) async {
        await withCheckedContinuation { continuation in
            firestoreService.listenForAIResponse(requestId: requestId) { [weak self] result in
                guard let self = self else { return }

                Task { @MainActor in
                    switch result {
                    case .success(let response):
                        if response.success {
                            self.analysisResult = response.response
                            print("✅ AI Analysis complete: \(response.response.prefix(100))...")
                        } else {
                            self.errorMessage = response.error ?? "AI request failed"
                        }
                    case .failure(let error):
                        self.errorMessage = error.localizedDescription
                        print("❌ AI Request failed: \(error.localizedDescription)")
                    }
                    self.isAnalyzing = false
                    continuation.resume()
                }
            }
        }
    }

    func cancelCurrentRequest() {
        // Cancel the current request and stop listening
        currentRequestId = nil
        isAnalyzing = false
        errorMessage = "Request cancelled"
    }

    // MARK: - Testing & Debugging

    func testFirestoreWrite() async {
        print("🧪 Testing direct Firestore write...")
        do {
            let db = Firestore.firestore()
            let testData: [String: Any] = [
                "message": "Test from iOS at \(Date())",
                "timestamp": FieldValue.serverTimestamp()
            ]

            let docRef = try await db.collection("test_writes").addDocument(data: testData)
            print("✅ Test write successful! Doc ID: \(docRef.documentID)")

            // Now test AI request write
            print("🧪 Testing AIRequest write...")
            let testRequest: [String: Any] = [
                "timestamp": FieldValue.serverTimestamp(),
                "request_type": "general_query",
                "status": "pending",
                "device_id": "iphone_app",
                "prompt": "Test prompt from iOS",
                "expires_at": Timestamp(date: Date().addingTimeInterval(600)),
                "retry_count": 0
            ]

            let requestRef = try await db.collection("ai_requests").addDocument(data: testRequest)
            print("✅ AI Request write successful! Doc ID: \(requestRef.documentID)")

        } catch {
            print("❌ Test write failed: \(error)")
            print("❌ Details: \(error.localizedDescription)")
        }
    }

    // MARK: - Simple General Analysis Request (for testing)

    func requestGeneralAnalysis() async {
        isAnalyzing = true
        errorMessage = nil
        analysisResult = nil

        do {
            // Simple general health check prompt
            let prompt = """
            Perform a general health check analysis of the PulseOne network monitoring system.

            Please provide:
            1. Overall system status assessment
            2. Any potential concerns or areas to monitor
            3. Recommendations for optimal performance
            4. General network health tips

            Keep the response concise and actionable.
            """

            // Create AI request
            let request = AIRequest.create(
                type: .generalQuery,
                prompt: prompt
            )

            print("📤 Submitting general analysis request...")

            // Submit to Firestore
            let requestId = try await firestoreService.submitAIRequest(request)
            currentRequestId = requestId

            print("✅ Request submitted with ID: \(requestId)")

            // Listen for response
            await waitForAIResponse(requestId: requestId)

        } catch {
            errorMessage = error.localizedDescription
            print("❌ Failed to submit request: \(error.localizedDescription)")
            isAnalyzing = false
        }
    }
}
