//
//  ChartView.swift
//  PulseOne
//
//  Simple chart component
//

import SwiftUI
import Charts

struct NetworkMetricsChart: View {
    let metrics: [NetworkMetrics]
    let metricType: MetricType

    enum MetricType: String, CaseIterable {
        case latency = "Ping (ms)"
        case wifiStrength = "WiFi Strength"
        case packetLoss = "Packet Loss (%)"
        case jitter = "Jitter (ms)"

        func value(from metric: NetworkMetrics) -> Double {
            switch self {
            case .latency: return metric.pingAvg
            case .wifiStrength: return Double(metric.wifiStrength)
            case .packetLoss: return metric.packetLoss
            case .jitter: return metric.pingJitter
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(metricType.rawValue)
                .font(.headline)
                .foregroundColor(.secondary)

            if #available(iOS 16.0, *) {
                Chart {
                    ForEach(metrics) { metric in
                        LineMark(
                            x: .value("Time", metric.timestampDate),
                            y: .value("Value", metricType.value(from: metric))
                        )
                        .foregroundStyle(.blue)
                        .interpolationMethod(.catmullRom)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
            } else {
                // Fallback for iOS 15
                Text("Charts require iOS 16+")
                    .foregroundColor(.secondary)
                    .frame(height: 200)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}
