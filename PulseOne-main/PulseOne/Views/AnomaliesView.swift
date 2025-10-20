//
//  AnomaliesView.swift
//  PulseOne
//
//  Anomalies and insights view
//

import SwiftUI
import Combine

struct AnomaliesView: View {
    @StateObject private var viewModel = AnomaliesViewModel()
    @State private var showResolvedOnly = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Filter Toggle
                Toggle("Show Resolved", isOn: $showResolvedOnly)
                    .padding(.horizontal)
                    .onChange(of: showResolvedOnly) { _ in
                        Task { await viewModel.loadAnomalies(includeResolved: showResolvedOnly) }
                    }

                // Anomaly List
                if !viewModel.anomalies.isEmpty {
                    ForEach(viewModel.anomalies) { anomaly in
                        NavigationLink(destination: AnomalyDetailView(anomaly: anomaly)) {
                            AnomalyBadge(anomaly: anomaly)
                                .padding(.horizontal)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green)
                        Text("All Clear!")
                            .font(.headline)
                        Text("No anomalies detected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }

                // Pattern Detection
                if !viewModel.patterns.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Detected Patterns")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.patterns, id: \.self) { pattern in
                            HStack(spacing: 12) {
                                Image(systemName: "waveform.path.ecg")
                                    .foregroundColor(.purple)
                                Text(pattern)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.purple.opacity(0.1))
                            .cornerRadius(12)
                            .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Anomalies & Insights")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await viewModel.loadAnomalies(includeResolved: showResolvedOnly) }
        }
        .refreshable {
            await viewModel.loadAnomalies(includeResolved: showResolvedOnly)
        }
    }
}

@MainActor
class AnomaliesViewModel: ObservableObject {
    @Published var anomalies: [Anomaly] = []
    @Published var patterns: [String] = []

    private let firestoreService = FirestoreService()
    private let deviceId = "raspberry_pi_001"

    func loadAnomalies(includeResolved: Bool) async {
        do {
            anomalies = try await firestoreService.fetchAnomalies(
                deviceId: deviceId,
                includeResolved: includeResolved
            )
            detectPatterns()
        } catch {
            print("Error loading anomalies: \(error)")
        }
    }

    private func detectPatterns() {
        var detectedPatterns: [String] = []

        // Count anomaly types
        let typeCounts = Dictionary(grouping: anomalies, by: { $0.type })
            .mapValues { $0.count }
            .filter { $0.value > 2 }

        for (type, count) in typeCounts {
            detectedPatterns.append("Recurring \(type.rawValue): \(count) occurrences")
        }

        // Check for time-based patterns (simplified)
        let recentAnomalies = anomalies.filter {
            $0.timestamp > Date().addingTimeInterval(-3600) // Last hour
        }

        if recentAnomalies.count > 3 {
            detectedPatterns.append("Elevated anomaly rate in the last hour")
        }

        patterns = detectedPatterns
    }
}

#Preview {
    NavigationView {
        AnomaliesView()
    }
}
