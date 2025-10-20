//
//  SettingsView.swift
//  PulseOne
//
//  App settings and configuration
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("deviceId") private var deviceId = "raspberry_pi_001"
    @AppStorage("notificationsEnabled") private var notificationsEnabled = true
    @AppStorage("refreshInterval") private var refreshInterval = 60.0
    @AppStorage("dataRetentionDays") private var dataRetentionDays = 30.0

    var body: some View {
        Form {
            Section("Device Configuration") {
                HStack {
                    Text("Device ID")
                    Spacer()
                    Text(deviceId)
                        .foregroundColor(.secondary)
                }

                NavigationLink("Raspberry Pi Status") {
                    RaspberryPiStatusView()
                }
            }

            Section("Notifications") {
                Toggle("Enable Alerts", isOn: $notificationsEnabled)

                if notificationsEnabled {
                    NavigationLink("Alert Preferences") {
                        NotificationPreferencesView()
                    }
                }
            }

            Section("Data & Performance") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Refresh Interval")
                    HStack {
                        Text("\(Int(refreshInterval))s")
                            .foregroundColor(.secondary)
                        Slider(value: $refreshInterval, in: 10...300, step: 10)
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Data Retention")
                    HStack {
                        Text("\(Int(dataRetentionDays)) days")
                            .foregroundColor(.secondary)
                        Slider(value: $dataRetentionDays, in: 7...90, step: 1)
                    }
                }
            }

            Section("AI Configuration") {
                NavigationLink("Model Settings") {
                    AIModelSettingsView()
                }

                NavigationLink("Training Data") {
                    TrainingDataView()
                }
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Build")
                    Spacer()
                    Text("2025.10.18")
                        .foregroundColor(.secondary)
                }

                Link("Documentation", destination: URL(string: "https://github.com")!)
                Link("Report Issue", destination: URL(string: "https://github.com")!)
            }

            Section {
                Button(role: .destructive, action: { }) {
                    Text("Clear All Data")
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct RaspberryPiStatusView: View {
    @State private var piStatus: PiStatus?

    struct PiStatus {
        let cpuUsage: Double
        let memoryUsage: Double
        let diskUsage: Double
        let uptime: String
        let temperature: Double
    }

    var body: some View {
        List {
            Section("System Resources") {
                HStack {
                    Text("CPU Usage")
                    Spacer()
                    Text("\(Int(piStatus?.cpuUsage ?? 0))%")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Memory")
                    Spacer()
                    Text("\(Int(piStatus?.memoryUsage ?? 0))%")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Disk")
                    Spacer()
                    Text("\(Int(piStatus?.diskUsage ?? 0))%")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Temperature")
                    Spacer()
                    Text(String(format: "%.1f°C", piStatus?.temperature ?? 0))
                        .foregroundColor(.secondary)
                }
            }

            Section("Status") {
                HStack {
                    Text("Uptime")
                    Spacer()
                    Text(piStatus?.uptime ?? "N/A")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Connection")
                    Spacer()
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("Connected")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Raspberry Pi")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct NotificationPreferencesView: View {
    @AppStorage("alertOnCritical") private var alertOnCritical = true
    @AppStorage("alertOnWarning") private var alertOnWarning = true
    @AppStorage("alertOnInfo") private var alertOnInfo = false

    var body: some View {
        Form {
            Section("Alert Severity") {
                Toggle("Critical Alerts", isOn: $alertOnCritical)
                Toggle("Warnings", isOn: $alertOnWarning)
                Toggle("Info", isOn: $alertOnInfo)
            }

            Section("Quiet Hours") {
                Toggle("Enable Quiet Hours", isOn: .constant(false))
            }
        }
        .navigationTitle("Alert Preferences")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AIModelSettingsView: View {
    var body: some View {
        Form {
            Section("Current Model") {
                HStack {
                    Text("Model Type")
                    Spacer()
                    Text("Gemini Pro")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("API Endpoint")
                    Spacer()
                    Text("Custom")
                        .foregroundColor(.secondary)
                }
            }

            Section("Inference Settings") {
                Toggle("On-Device Processing", isOn: .constant(false))
                Toggle("Cloud Fallback", isOn: .constant(true))
            }

            Section {
                Text("Replace with your own API endpoint in GeminiService.swift")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Model Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TrainingDataView: View {
    var body: some View {
        List {
            Section("Data Collection") {
                HStack {
                    Text("Total Samples")
                    Spacer()
                    Text("0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("Last Trained")
                    Spacer()
                    Text("Never")
                        .foregroundColor(.secondary)
                }
            }

            Section("Feedback Loop") {
                Toggle("Auto-Retrain", isOn: .constant(false))
                Toggle("Collect Feedback", isOn: .constant(true))
            }

            Section {
                Button("Export Training Data") { }
                Button("Import Data") { }
            }
        }
        .navigationTitle("Training Data")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
}
