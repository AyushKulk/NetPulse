//
//  AIAgentView.swift
//  PulseOne
//
//  AI Agent control and monitoring
//

import SwiftUI

struct AIAgentView: View {
    @StateObject private var viewModel = AIAgentViewModel()
    @State private var showingAnalysisSheet = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Agent Status Card
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "brain")
                            .font(.largeTitle)
                            .foregroundColor(.purple)

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text(viewModel.agentState?.status.rawValue.uppercased() ?? "OFFLINE")
                                .font(.caption)
                                .fontWeight(.bold)
                                .foregroundColor(statusColor)
                            if let task = viewModel.agentState?.currentTask {
                                Text(task)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Model Version")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(viewModel.agentState?.modelVersion ?? "N/A")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Accuracy")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            if let accuracy = viewModel.agentState?.accuracyScore {
                                Text(String(format: "%.1f%%", accuracy))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.green)
                            } else {
                                Text("N/A")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // Quick Actions
                VStack(spacing: 12) {
                    // Debug test button
                    Button(action: {
                        Task {
                            print("🧪 Debug test button tapped!")
                            await viewModel.testFirestoreWrite()
                        }
                    }) {
                        HStack {
                            Image(systemName: "hammer.circle.fill")
                            Text("Debug: Test Firestore")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.orange)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }

                    // Simple test button
                    Button(action: {
                        Task {
                            print("🔘 Test button tapped!")
                            await viewModel.requestGeneralAnalysis()
                        }
                    }) {
                        HStack {
                            Image(systemName: "play.circle.fill")
                            Text("Quick Test Request")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isAnalyzing)

                    Button(action: { showingAnalysisSheet = true }) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal")
                            Text("Request AI Analysis")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(viewModel.isAnalyzing)
                }
                .padding(.horizontal)

                // Error Message
                if let error = viewModel.errorMessage {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.red)
                            Text("Error")
                                .font(.headline)
                            Spacer()
                            Button(action: { viewModel.errorMessage = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }

                        Text(error)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Analysis Result
                if let result = viewModel.analysisResult {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("AI Analysis")
                                .font(.headline)
                            Spacer()
                            Button(action: { viewModel.analysisResult = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }

                        Text(result)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Show current request ID for debugging
                if let requestId = viewModel.currentRequestId {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Request ID")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(requestId)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.blue)
                            .textSelection(.enabled)
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }

                // Recent Actions
                VStack(alignment: .leading, spacing: 12) {
                    Text("Recent Actions")
                        .font(.headline)
                        .padding(.horizontal)

                    if !viewModel.recentActions.isEmpty {
                        ForEach(viewModel.recentActions.prefix(10)) { action in
                            AgentActionCard(action: action)
                                .padding(.horizontal)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "list.bullet.clipboard")
                                .font(.system(size: 50))
                                .foregroundColor(.gray)
                            Text("No actions yet")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }

                if viewModel.isAnalyzing {
                    HStack(spacing: 12) {
                        ProgressView()
                        Text("AI is analyzing...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("AI Agent")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening()
        }
        .sheet(isPresented: $showingAnalysisSheet) {
            AIAnalysisRequestView(viewModel: viewModel)
        }
    }

    private var statusColor: Color {
        switch viewModel.agentState?.status {
        case .idle: return .green
        case .analyzing, .acting: return .blue
        case .waiting: return .orange
        case .none: return .gray
        }
    }
}

struct AgentActionCard: View {
    let action: AIAgentAction

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: action.success ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(action.success ? .green : .red)

                Text(action.actionType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.subheadline)
                    .fontWeight(.semibold)

                Spacer()

                Text(action.timestamp, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            Text(action.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)

            if let response = action.aiResponse {
                Text(response)
                    .font(.caption2)
                    .foregroundColor(.purple)
                    .lineLimit(3)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct AIAnalysisRequestView: View {
    @ObservedObject var viewModel: AIAgentViewModel
    @Environment(\.dismiss) var dismiss
    @State private var selectedAnalysisType = AnalysisType.general

    enum AnalysisType: String, CaseIterable {
        case general = "General Health Check"
        case correlations = "Environmental Correlations"
        case predictions = "Predictive Analysis"
    }

    var body: some View {
        NavigationView {
            Form {
                Section("Analysis Type") {
                    Picker("Type", selection: $selectedAnalysisType) {
                        ForEach(AnalysisType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.inline)
                }

                Section("Description") {
                    Text(descriptionForType)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section {
                    Button("Request Analysis") {
                        Task {
                            await performAnalysis()
                            dismiss()
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .disabled(viewModel.isAnalyzing)
                }
            }
            .navigationTitle("AI Analysis")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var descriptionForType: String {
        switch selectedAnalysisType {
        case .general:
            return "Comprehensive analysis of current network health, sensor data, and potential issues."
        case .correlations:
            return "Analyze correlations between environmental sensors and network performance degradation."
        case .predictions:
            return "Predict potential future issues based on current trends and historical data."
        }
    }

    private func performAnalysis() async {
        switch selectedAnalysisType {
        case .general:
            // Create a general query request
            await viewModel.requestGeneralAnalysis()
        case .correlations:
            // This requires fetching metrics and sensors first
            // For now, use a simple request
            await viewModel.requestGeneralAnalysis()
        case .predictions:
            // Predictive analysis
            await viewModel.requestGeneralAnalysis()
        }
    }
}

#Preview {
    NavigationView {
        AIAgentView()
    }
}
