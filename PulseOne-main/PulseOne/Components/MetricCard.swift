//
//  MetricCard.swift
//  PulseOne
//
//  Reusable metric display card
//

import SwiftUI

struct MetricCard: View {
    let title: String
    let value: String
    let unit: String
    let trend: Trend?
    let color: Color

    enum Trend {
        case up, down, stable

        var icon: String {
            switch self {
            case .up: return "arrow.up.right"
            case .down: return "arrow.down.right"
            case .stable: return "minus"
            }
        }

        var color: Color {
            switch self {
            case .up: return .green
            case .down: return .red
            case .stable: return .gray
            }
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.caption2)
                        .foregroundColor(trend.color)
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(color)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
    }
}

struct HealthScoreRing: View {
    let score: Double
    let size: CGFloat

    private var color: Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .orange
        default: return .red
        }
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: size * 0.1)

            Circle()
                .trim(from: 0, to: score / 100)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.1, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut, value: score)

            VStack(spacing: 4) {
                Text("\(Int(score))")
                    .font(.system(size: size * 0.3, weight: .bold))
                    .foregroundColor(color)
                Text("Health")
                    .font(.system(size: size * 0.12))
                    .foregroundColor(.secondary)
            }
        }
        .frame(width: size, height: size)
    }
}

struct AnomalyBadge: View {
    let anomaly: Anomaly

    private var backgroundColor: Color {
        switch anomaly.severity {
        case .critical: return .red.opacity(0.1)
        case .warning: return .orange.opacity(0.1)
        case .info: return .blue.opacity(0.1)
        }
    }

    private var iconColor: Color {
        switch anomaly.severity {
        case .critical: return .red
        case .warning: return .orange
        case .info: return .blue
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(iconColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(anomaly.type.rawValue.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.headline)
                Text(anomaly.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Text(anomaly.severity.rawValue.uppercased())
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(iconColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(iconColor.opacity(0.2))
                .cornerRadius(6)
        }
        .padding()
        .background(backgroundColor)
        .cornerRadius(12)
    }
}

struct SensorStatusCard: View {
    let sensorType: SensorType
    let value: Double
    let unit: String
    let isNormal: Bool

    private var icon: String {
        switch sensorType {
        case .temperature: return "thermometer"
        case .humidity: return "humidity"
        case .motion: return "wave.3.right"
        case .vibration: return "waveform.path.ecg"
        case .powerDraw: return "bolt.fill"
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(isNormal ? .blue : .red)
                Spacer()
                Circle()
                    .fill(isNormal ? Color.green : Color.red)
                    .frame(width: 8, height: 8)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(sensorType.rawValue.capitalized)
                    .font(.caption)
                    .foregroundColor(.secondary)
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(String(format: "%.1f", value))
                        .font(.title2)
                        .fontWeight(.bold)
                    Text(unit)
                        .font(.caption)
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
}
