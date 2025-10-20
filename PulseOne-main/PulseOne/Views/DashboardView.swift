//
//  DashboardView.swift
//  PulseOne
//
//  Main dashboard screen
//

import SwiftUI

struct DashboardView: View {
    @StateObject private var viewModel = DashboardViewModel()
    @State private var showingError = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Health Score Ring
                    HealthScoreRing(score: viewModel.healthScore, size: 150)
                        .padding(.vertical)

                    // Network Stats Grid
                    if let metrics = viewModel.latestMetrics {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Network Metrics")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                MetricCard(
                                    title: "Ping",
                                    value: String(format: "%.0f", metrics.pingAvg),
                                    unit: "ms",
                                    trend: metrics.pingAvg < 50 ? .stable : .up,
                                    color: metrics.pingAvg < 50 ? .green : .orange
                                )

                                MetricCard(
                                    title: "Packet Loss",
                                    value: String(format: "%.1f", metrics.packetLoss),
                                    unit: "%",
                                    trend: metrics.packetLoss < 1 ? .stable : .up,
                                    color: metrics.packetLoss < 1 ? .green : .red
                                )

                                MetricCard(
                                    title: "Jitter",
                                    value: String(format: "%.1f", metrics.pingJitter),
                                    unit: "ms",
                                    trend: metrics.pingJitter < 10 ? .stable : .up,
                                    color: metrics.pingJitter < 10 ? .green : .orange
                                )

                                MetricCard(
                                    title: "WiFi Strength",
                                    value: String(format: "%d", metrics.wifiStrength),
                                    unit: "",
                                    trend: metrics.wifiStrength > 30 ? .stable : .down,
                                    color: metrics.wifiStrength > 30 ? .green : .orange
                                )

                                MetricCard(
                                    title: "Humidity",
                                    value: String(format: "%.0f", metrics.humidity),
                                    unit: "%",
                                    trend: .stable,
                                    color: .blue
                                )

                                MetricCard(
                                    title: "Motion Level",
                                    value: String(format: "%d", metrics.motionLevel),
                                    unit: "",
                                    trend: .stable,
                                    color: .purple
                                )
                            }
                            .padding(.horizontal)
                        }

                        // System Health Stats
                        VStack(alignment: .leading, spacing: 12) {
                            Text("System Health")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                MetricCard(
                                    title: "CPU Load",
                                    value: String(format: "%.0f", metrics.cpuLoad),
                                    unit: "%",
                                    trend: metrics.cpuLoad < 80 ? .stable : .up,
                                    color: metrics.cpuLoad < 80 ? .green : .orange
                                )

                                MetricCard(
                                    title: "CPU Temp",
                                    value: String(format: "%.1f", metrics.cpuTemp),
                                    unit: "°C",
                                    trend: metrics.cpuTemp < 70 ? .stable : .up,
                                    color: metrics.cpuTemp < 70 ? .green : .red
                                )

                                MetricCard(
                                    title: "Ambient Temp",
                                    value: String(format: "%.1f", metrics.ambientTemp),
                                    unit: "°C",
                                    trend: .stable,
                                    color: .cyan
                                )

                                MetricCard(
                                    title: "Data Received",
                                    value: String(format: "%.1f", Double(metrics.bytesRecv) / 1_000_000),
                                    unit: "MB",
                                    trend: .stable,
                                    color: .purple
                                )
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Active Anomalies
                    if !viewModel.activeAnomalies.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Active Alerts")
                                .font(.headline)
                                .padding(.horizontal)

                            ForEach(viewModel.activeAnomalies.prefix(3)) { anomaly in
                                NavigationLink(destination: AnomalyDetailView(anomaly: anomaly)) {
                                    AnomalyBadge(anomaly: anomaly)
                                        .padding(.horizontal)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }

                            if viewModel.activeAnomalies.count > 3 {
                                NavigationLink(destination: AnomaliesView()) {
                                    Text("View all \(viewModel.activeAnomalies.count) alerts")
                                        .font(.caption)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal)
                                }
                            }
                        }
                    }

                    // Recent Sensor Readings
                    if !viewModel.recentSensorData.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sensors")
                                .font(.headline)
                                .padding(.horizontal)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                                ForEach(groupedSensorData, id: \.key) { sensorType, data in
                                    if let latest = data.first {
                                        SensorStatusCard(
                                            sensorType: sensorType,
                                            value: latest.value,
                                            unit: latest.unit,
                                            isNormal: latest.isNormal
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Quick Actions
                    VStack(spacing: 12) {
                        Button(action: { Task { await viewModel.refresh() } }) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Refresh Data")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                        .disabled(viewModel.isLoading)

                        NavigationLink(destination: AIAgentView()) {
                            HStack {
                                Image(systemName: "brain")
                                Text("AI Analysis")
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("PulseOne")
            .navigationBarTitleDisplayMode(.large)
            .onAppear {
                viewModel.startListening()
            }
            .onDisappear {
                viewModel.stopListening()
            }
            .refreshable {
                await viewModel.refresh()
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                Text(viewModel.errorMessage ?? "Unknown error")
            }
            .onChange(of: viewModel.errorMessage) { error in
                showingError = error != nil
            }
        }
    }

    private var groupedSensorData: [(key: SensorType, value: [SensorData])] {
        Dictionary(grouping: viewModel.recentSensorData, by: { $0.sensorType })
            .sorted { $0.key.rawValue < $1.key.rawValue }
    }
}

struct AnomalyDetailView: View {
    let anomaly: Anomaly

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(anomaly.description)
                    .font(.title2)
                    .fontWeight(.bold)

                if let rootCause = anomaly.rootCause {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Root Cause")
                            .font(.headline)
                        Text(rootCause)
                            .foregroundColor(.secondary)
                    }
                }

                if let recommendation = anomaly.recommendedAction {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Recommended Action")
                            .font(.headline)
                        Text(recommendation)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Detected")
                        .font(.headline)
                    Text(anomaly.timestamp, style: .relative)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
        }
        .navigationTitle("Anomaly Details")
    }
}

#Preview {
    DashboardView()
}
