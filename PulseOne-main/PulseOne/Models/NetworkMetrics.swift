//
//  NetworkMetrics.swift
//  PulseOne
//
//  Network metrics data model
//

import Foundation
import FirebaseFirestore

struct NetworkMetrics: Codable, Identifiable {
    @DocumentID var id: String?

    // Core fields
    var timestamp: Timestamp // Firestore timestamp
    var category: String // "Normal" or anomaly type
    var isAnomaly: Int // 0 or 1

    // Network metrics
    var pingAvg: Double
    var pingJitter: Double
    var packetLoss: Double
    var wifiStrength: Int

    // System metrics
    var cpuLoad: Double
    var cpuTemp: Double
    var ambientTemp: Double
    var humidity: Double

    // Motion sensors (accelerometer)
    var ax: Int
    var ay: Int
    var az: Int

    // Motion sensors (gyroscope)
    var gx: Int
    var gy: Int
    var gz: Int

    // Motion analysis
    var motionLevel: Int

    // Network traffic
    var bytesRecv: Int
    var bytesSent: Int

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case category
        case isAnomaly = "is_anomaly"
        case pingAvg = "ping_avg"
        case pingJitter = "ping_jitter"
        case packetLoss = "packet_loss"
        case wifiStrength = "wifi_strength"
        case cpuLoad = "cpu_load"
        case cpuTemp = "cpu_temp"
        case ambientTemp = "ambient_temp"
        case humidity
        case ax
        case ay
        case az
        case gx
        case gy
        case gz
        case motionLevel = "motion_level"
        case bytesRecv = "bytes_recv"
        case bytesSent = "bytes_sent"
    }

    // Convert Firestore timestamp to Date
    var timestampDate: Date {
        timestamp.dateValue()
    }

    // Legacy compatibility - map to old property names for backward compatibility
    var pingMs: Double { pingAvg }
    var jitterMs: Double { pingJitter }
    var packetLossPercent: Double { packetLoss }
    var wifiRssiDbm: Double { Double(wifiStrength) }
    var cpuPercent: Double { cpuLoad }
    var temperatureC: Double { cpuTemp }
    var memoryPercent: Double { 0 } // Not available in new schema

    // Additional legacy names
    var latency: Double { pingAvg }
    var throughputDown: Double { 0 } // Not available in new schema
    var throughputUp: Double { 0 } // Not available in new schema
    var signalStrength: Double { Double(wifiStrength) }
    var jitter: Double { pingJitter }

    // Computed health score (0-100)
    var healthScore: Double {
        var score = 100.0

        // Latency penalty (target: <50ms)
        if pingAvg > 50 { score -= min(20, (pingAvg - 50) / 10) }

        // Packet loss penalty
        score -= packetLoss * 5

        // Jitter penalty (target: <10ms)
        if pingJitter > 10 { score -= min(15, (pingJitter - 10) / 2) }

        // WiFi signal strength penalty (target: 0 is worst, higher is better)
        // Assuming wifi_strength is 0-100 scale or similar
        if wifiStrength < 30 { score -= min(15, Double(30 - wifiStrength) / 2) }

        // CPU usage penalty (target: <80%)
        if cpuLoad > 80 { score -= min(10, (cpuLoad - 80) / 5) }

        // Temperature penalty (target: <70°C)
        if cpuTemp > 70 { score -= min(10, (cpuTemp - 70) / 3) }

        return max(0, score)
    }

    // System health check
    var systemHealthy: Bool {
        cpuLoad < 90 && cpuTemp < 80
    }

    // Network health check
    var networkHealthy: Bool {
        pingAvg < 100 && packetLoss < 1 && wifiStrength > 20
    }
}
