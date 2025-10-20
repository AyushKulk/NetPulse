#!/usr/bin/env python3
"""
Script to add new Swift files to Xcode project
Run this from the project root directory
"""

import subprocess
import os

# Change to project directory
os.chdir('/Users/joelin/Local/PulseOne')

# List of files to add (relative to PulseOne folder)
files = [
    'Models/NetworkMetrics.swift',
    'Models/SensorData.swift',
    'Models/Anomaly.swift',
    'Models/AIAgentAction.swift',
    'Views/DashboardView.swift',
    'Views/NetworkMonitorView.swift',
    'Views/SensorsDashboardView.swift',
    'Views/AnomaliesView.swift',
    'Views/AIAgentView.swift',
    'Views/SettingsView.swift',
    'ViewModels/DashboardViewModel.swift',
    'ViewModels/NetworkMonitorViewModel.swift',
    'ViewModels/AIAgentViewModel.swift',
    'Services/FirestoreService.swift',
    'Services/GeminiService.swift',
    'Components/MetricCard.swift',
    'Components/ChartView.swift',
]

print("Files need to be added to Xcode project manually.")
print("\nInstructions:")
print("1. Open PulseOne.xcodeproj in Xcode")
print("2. Right-click on 'PulseOne' folder in the navigator")
print("3. Select 'Add Files to PulseOne...'")
print("4. Add the following folders (with 'Create groups' option):")
print("   - Models/")
print("   - Views/")
print("   - ViewModels/")
print("   - Services/")
print("   - Components/")
print("\nOr add each file individually:")
for f in files:
    print(f"   - PulseOne/{f}")
