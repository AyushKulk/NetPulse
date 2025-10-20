//
//  GeminiService.swift
//  PulseOne
//
//  Gemini AI service for network analysis
//

import Foundation

struct GeminiRequest: Codable {
    let contents: [Content]

    struct Content: Codable {
        let parts: [Part]

        struct Part: Codable {
            let text: String
        }
    }
}

struct GeminiResponse: Codable {
    let candidates: [Candidate]

    struct Candidate: Codable {
        let content: Content

        struct Content: Codable {
            let parts: [Part]

            struct Part: Codable {
                let text: String
            }
        }
    }

    var text: String? {
        candidates.first?.content.parts.first?.text
    }
}

class GeminiService {
    // Replace with your own API endpoint
    private let apiKey = "YOUR_GEMINI_API_KEY" // TODO: Move to secure storage
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent"

    func analyzeNetworkIssue(metrics: NetworkMetrics, sensorData: [SensorData], anomaly: Anomaly?) async throws -> String {
        let prompt = buildAnalysisPrompt(metrics: metrics, sensorData: sensorData, anomaly: anomaly)
        return try await sendRequest(prompt: prompt)
    }

    func suggestHealingAction(anomaly: Anomaly, context: String) async throws -> String {
        let prompt = """
        As a network healing AI agent, analyze this issue and suggest specific actions:

        Issue: \(anomaly.description)
        Type: \(anomaly.type.rawValue)
        Severity: \(anomaly.severity.rawValue)
        Context: \(context)

        Provide:
        1. Root cause analysis
        2. Step-by-step healing actions
        3. Expected outcome
        4. Preventive measures

        Be concise and actionable.
        """
        return try await sendRequest(prompt: prompt)
    }

    func analyzeCorrelations(networkMetrics: [NetworkMetrics], sensorData: [SensorData]) async throws -> String {
        let prompt = """
        Analyze correlations between network performance and environmental sensors:

        Network Data Summary:
        - Avg Latency: \(networkMetrics.map(\.latency).reduce(0, +) / Double(networkMetrics.count))ms
        - Avg Packet Loss: \(networkMetrics.map(\.packetLoss).reduce(0, +) / Double(networkMetrics.count))%

        Sensor Data Summary:
        \(summarizeSensorData(sensorData))

        Find patterns and correlations that might indicate network issues.
        """
        return try await sendRequest(prompt: prompt)
    }

    // MARK: - Private Methods

    private func sendRequest(prompt: String) async throws -> String {
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw URLError(.badURL)
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let geminiRequest = GeminiRequest(
            contents: [
                GeminiRequest.Content(
                    parts: [GeminiRequest.Content.Part(text: prompt)]
                )
            ]
        )

        request.httpBody = try JSONEncoder().encode(geminiRequest)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw URLError(.badServerResponse)
        }

        let geminiResponse = try JSONDecoder().decode(GeminiResponse.self, from: data)
        return geminiResponse.text ?? "No response from AI"
    }

    private func buildAnalysisPrompt(metrics: NetworkMetrics, sensorData: [SensorData], anomaly: Anomaly?) -> String {
        var prompt = """
        Analyze this network health data:

        Network Metrics:
        - Latency: \(metrics.latency)ms
        - Throughput Down: \(metrics.throughputDown) Mbps
        - Throughput Up: \(metrics.throughputUp) Mbps
        - Packet Loss: \(metrics.packetLoss)%
        - Signal Strength: \(metrics.signalStrength) dBm
        - Jitter: \(metrics.jitter)ms
        - Health Score: \(metrics.healthScore)/100

        Environmental Sensors:
        \(summarizeSensorData(sensorData))
        """

        if let anomaly = anomaly {
            prompt += """

            Detected Anomaly:
            - Type: \(anomaly.type.rawValue)
            - Severity: \(anomaly.severity.rawValue)
            - Description: \(anomaly.description)
            """
        }

        prompt += """

        Provide:
        1. Overall health assessment
        2. Issues identified
        3. Correlation between environmental factors and network performance
        4. Recommendations
        """

        return prompt
    }

    private func summarizeSensorData(_ data: [SensorData]) -> String {
        let grouped = Dictionary(grouping: data, by: { $0.sensorType })
        return grouped.map { type, readings in
            let avg = readings.map(\.value).reduce(0, +) / Double(readings.count)
            let unit = readings.first?.unit ?? ""
            return "- \(type.rawValue): \(String(format: "%.2f", avg)) \(unit)"
        }.joined(separator: "\n")
    }
}
