#!/usr/bin/env ruby
require 'xcodeproj'

project_path = 'PulseOne.xcodeproj'
project = Xcodeproj::Project.open(project_path)

# Get the main target
target = project.targets.first

# Get the main group
main_group = project.main_group['PulseOne']

# Create groups if they don't exist
models_group = main_group.find_subpath('Models', true)
views_group = main_group.find_subpath('Views', true)
viewmodels_group = main_group.find_subpath('ViewModels', true)
services_group = main_group.find_subpath('Services', true)
components_group = main_group.find_subpath('Components', true)

# Files to add
files_to_add = {
  models_group => [
    'PulseOne/Models/NetworkMetrics.swift',
    'PulseOne/Models/SensorData.swift',
    'PulseOne/Models/Anomaly.swift',
    'PulseOne/Models/AIAgentAction.swift'
  ],
  views_group => [
    'PulseOne/Views/DashboardView.swift',
    'PulseOne/Views/NetworkMonitorView.swift',
    'PulseOne/Views/SensorsDashboardView.swift',
    'PulseOne/Views/AnomaliesView.swift',
    'PulseOne/Views/AIAgentView.swift',
    'PulseOne/Views/SettingsView.swift'
  ],
  viewmodels_group => [
    'PulseOne/ViewModels/DashboardViewModel.swift',
    'PulseOne/ViewModels/NetworkMonitorViewModel.swift',
    'PulseOne/ViewModels/AIAgentViewModel.swift'
  ],
  services_group => [
    'PulseOne/Services/FirestoreService.swift',
    'PulseOne/Services/GeminiService.swift'
  ],
  components_group => [
    'PulseOne/Components/MetricCard.swift',
    'PulseOne/Components/ChartView.swift'
  ]
}

# Add files to groups and target
files_to_add.each do |group, file_paths|
  file_paths.each do |file_path|
    # Check if file already exists in group
    file_name = File.basename(file_path)
    next if group.files.any? { |f| f.path == file_name }

    # Add file reference
    file_ref = group.new_file(file_path)

    # Add to target build phase
    target.add_file_references([file_ref])
  end
end

# Save the project
project.save

puts "Files added to Xcode project successfully!"
