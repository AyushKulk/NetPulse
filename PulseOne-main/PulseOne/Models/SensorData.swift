//
//  SensorData.swift
//  PulseOne
//
//  Sensor data models
//

import Foundation
import FirebaseFirestore

enum SensorType: String, Codable {
    case temperature
    case humidity
    case motion
    case vibration
    case powerDraw = "power_draw"
}

struct SensorData: Codable, Identifiable {
    @DocumentID var id: String?
    var timestamp: Date
    var sensorType: SensorType
    var value: Double
    var unit: String
    var deviceId: String
    var arduinoId: String

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case sensorType = "sensor_type"
        case value
        case unit
        case deviceId = "device_id"
        case arduinoId = "arduino_id"
    }

    var isNormal: Bool {
        switch sensorType {
        case .temperature:
            return value >= 15 && value <= 35 // Celsius
        case .humidity:
            return value >= 30 && value <= 70 // Percentage
        case .motion, .vibration:
            return value < 100 // Arbitrary threshold
        case .powerDraw:
            return value < 5.0 // Watts
        }
    }
}

struct SensorStatus: Identifiable {
    let id: String
    let sensorType: SensorType
    let isOnline: Bool
    let lastReading: Date?
    let currentValue: Double?
    let arduinoId: String
}
