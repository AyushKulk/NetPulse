#!/bin/bash

# This script helps you add the new files to Xcode project
# It will open Xcode and provide instructions

echo "================================================"
echo "PulseOne - Add Files to Xcode Project"
echo "================================================"
echo ""
echo "Opening Xcode project..."

# Open Xcode
open PulseOne.xcodeproj

echo ""
echo "Follow these steps in Xcode:"
echo ""
echo "1. Wait for Xcode to open"
echo "2. In the Project Navigator (left sidebar), right-click on 'PulseOne' folder"
echo "3. Select 'Add Files to \"PulseOne\"...'"
echo "4. In the file dialog, navigate to:"
echo "   $(pwd)/PulseOne/"
echo ""
echo "5. Select ALL these folders (hold Cmd to select multiple):"
echo "   ✓ Models"
echo "   ✓ Services"
echo "   ✓ ViewModels"
echo "   ✓ Views"
echo "   ✓ Components"
echo ""
echo "6. IMPORTANT: Before clicking 'Add', verify:"
echo "   ✓ 'Create groups' is selected (NOT 'Create folder references')"
echo "   ✓ 'PulseOne' target is checked"
echo "   ✗ 'Copy items if needed' is UNCHECKED"
echo ""
echo "7. Click 'Add'"
echo ""
echo "================================================"
echo "After adding files:"
echo "- Press Cmd+B to build the project"
echo "- Fix any errors if they appear"
echo "- Press Cmd+R to run the app"
echo "================================================"
