//
//  SensorsDashboardView.swift
//  PulseOne
//
//  Environmental sensors dashboard
//

import SwiftUI
import Combine

struct SensorsDashboardView: View {
    @StateObject private var viewModel = SensorsDashboardViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Sensor Status Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(viewModel.sensorStatuses) { status in
                        SensorDetailCard(status: status)
                    }
                }
                .padding(.horizontal)

                // Environmental Correlations
                if !viewModel.correlationInsights.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Insights")
                            .font(.headline)
                            .padding(.horizontal)

                        ForEach(viewModel.correlationInsights, id: \.self) { insight in
                            HStack(spacing: 12) {
                                Image(systemName: "lightbulb.fill")
                                    .foregroundColor(.yellow)
                                Text(insight)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color(.systemBackground))
                            .cornerRadius(12)
                            .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                            .padding(.horizontal)
                        }
                    }
                }

                // Arduino Devices
                VStack(alignment: .leading, spacing: 12) {
                    Text("Connected Devices")
                        .font(.headline)
                        .padding(.horizontal)

                    ForEach(viewModel.arduinoDevices, id: \.self) { deviceId in
                        HStack {
                            Image(systemName: "cpu")
                                .foregroundColor(.blue)
                            Text(deviceId)
                                .font(.subheadline)
                            Spacer()
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(12)
                        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                        .padding(.horizontal)
                    }
                }

                if viewModel.sensorStatuses.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "sensor")
                            .font(.system(size: 60))
                            .foregroundColor(.gray)
                        Text("No sensors detected")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Text("Make sure your Arduino devices are connected")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Sensors")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            viewModel.startListening()
        }
        .refreshable {
            await viewModel.refresh()
        }
    }
}

struct SensorDetailCard: View {
    let status: SensorStatus

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: iconForSensor(status.sensorType))
                    .font(.title2)
                    .foregroundColor(status.isOnline ? .blue : .gray)
                Spacer()
                Circle()
                    .fill(status.isOnline ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(status.sensorType.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)

                if let value = status.currentValue {
                    Text(String(format: "%.1f", value))
                        .font(.title2)
                        .fontWeight(.bold)
                } else {
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }

                if let lastReading = status.lastReading {
                    Text(lastReading, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Text("No data")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }

    private func iconForSensor(_ type: SensorType) -> String {
        switch type {
        case .temperature: return "thermometer"
        case .humidity: return "humidity"
        case .motion: return "wave.3.right"
        case .vibration: return "waveform.path.ecg"
        case .powerDraw: return "bolt.fill"
        }
    }
}

@MainActor
class SensorsDashboardViewModel: ObservableObject {
    @Published var sensorStatuses: [SensorStatus] = []
    @Published var correlationInsights: [String] = []
    @Published var arduinoDevices: [String] = []

    private let firestoreService = FirestoreService()
    private let deviceId = "raspberry_pi_001"

    func startListening() {
        firestoreService.listenToSensorData(deviceId: deviceId) { [weak self] data in
            self?.updateSensorStatuses(from: data)
        }
    }

    func refresh() async {
        do {
            let data = try await firestoreService.fetchSensorData(deviceId: deviceId)
            updateSensorStatuses(from: data)
        } catch {
            print("Error refreshing sensors: \(error)")
        }
    }

    private func updateSensorStatuses(from data: [SensorData]) {
        let grouped = Dictionary(grouping: data, by: { $0.sensorType })
        let devices = Set(data.map { $0.arduinoId })

        sensorStatuses = grouped.map { type, readings in
            let latest = readings.first
            return SensorStatus(
                id: type.rawValue,
                sensorType: type,
                isOnline: latest != nil,
                lastReading: latest?.timestamp,
                currentValue: latest?.value,
                arduinoId: latest?.arduinoId ?? ""
            )
        }.sorted { $0.sensorType.rawValue < $1.sensorType.rawValue }

        arduinoDevices = Array(devices).sorted()

        // Generate simple insights
        generateInsights(from: data)
    }

    private func generateInsights(from data: [SensorData]) {
        var insights: [String] = []

        if let temp = data.first(where: { $0.sensorType == .temperature }) {
            if temp.value > 30 {
                insights.append("High temperature detected - may affect network equipment")
            }
        }

        if let humidity = data.first(where: { $0.sensorType == .humidity }) {
            if humidity.value > 65 {
                insights.append("High humidity levels - monitor for condensation")
            }
        }

        correlationInsights = insights
    }
}

#Preview {
    NavigationView {
        SensorsDashboardView()
    }
}
