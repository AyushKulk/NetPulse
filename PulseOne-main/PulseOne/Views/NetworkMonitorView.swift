//
//  NetworkMonitorView.swift
//  PulseOne
//
//  Network metrics monitoring
//

import SwiftUI

struct NetworkMonitorView: View {
    @StateObject private var viewModel = NetworkMonitorViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Time Range Selector
                Picker("Time Range", selection: $viewModel.selectedTimeRange) {
                    ForEach(NetworkMonitorViewModel.TimeRange.allCases, id: \.self) { range in
                        Text(range.rawValue).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.selectedTimeRange) { _ in
                    Task { await viewModel.loadMetrics() }
                }

                // Summary Stats
                HStack(spacing: 20) {
                    VStack {
                        Text("Avg Latency")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(viewModel.averageLatency)) ms")
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Divider()

                    VStack {
                        Text("Avg Loss")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(String(format: "%.2f%%", viewModel.averagePacketLoss))
                            .font(.title3)
                            .fontWeight(.bold)
                    }

                    Divider()

                    VStack {
                        Text("Data Points")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(viewModel.metricsHistory.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                    }
                }
                .frame(height: 60)
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                .padding(.horizontal)

                // Charts
                if !viewModel.metricsHistory.isEmpty {
                    NetworkMetricsChart(
                        metrics: viewModel.metricsHistory,
                        metricType: .latency
                    )
                    .padding(.horizontal)

                    NetworkMetricsChart(
                        metrics: viewModel.metricsHistory,
                        metricType: .wifiStrength
                    )
                    .padding(.horizontal)

                    NetworkMetricsChart(
                        metrics: viewModel.metricsHistory,
                        metricType: .packetLoss
                    )
                    .padding(.horizontal)

                    NetworkMetricsChart(
                        metrics: viewModel.metricsHistory,
                        metricType: .jitter
                    )
                    .padding(.horizontal)
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No data available")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Waiting for network metrics...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Network Monitor")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task { await viewModel.loadMetrics() }
            viewModel.startLiveUpdates()
        }
        .refreshable {
            await viewModel.loadMetrics()
        }
    }
}

#Preview {
    NavigationView {
        NetworkMonitorView()
    }
}
