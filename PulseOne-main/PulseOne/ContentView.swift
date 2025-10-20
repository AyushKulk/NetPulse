//
//  ContentView.swift
//  PulseOne
//
//  Main app navigation
//

import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            DashboardView()
                .tabItem {
                    Label("Dashboard", systemImage: "gauge")
                }
                .tag(0)

            NetworkMonitorView()
                .tabItem {
                    Label("Network", systemImage: "network")
                }
                .tag(1)

            SensorsDashboardView()
                .tabItem {
                    Label("Sensors", systemImage: "sensor")
                }
                .tag(2)

            AnomaliesView()
                .tabItem {
                    Label("Insights", systemImage: "lightbulb")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
                .tag(4)
        }
    }
}

#Preview {
    ContentView()
}

