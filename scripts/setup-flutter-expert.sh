#!/bin/bash

# Flutter Expert Setup Script
# This script sets up the flutter-expert skill locally for pre-commit analysis

set -e

echo "🚀 Flutter Expert Skill - Local Setup"
echo "====================================="
echo ""

# Check Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Please install Flutter first."
    exit 1
fi

echo "✅ Flutter detected"

# Get Flutter packages
echo "📦 Getting Flutter packages..."
flutter pub get

# Install Dart Code Metrics globally
echo "📊 Installing Dart Code Metrics..."
dart pub global activate dart_code_metrics

# Install Dependency Validator
echo "📦 Installing Dependency Validator..."
dart pub global activate dependency_validator

# Add to PATH if not already there
if [[ ":$PATH:" == *":$HOME/.pub-cache/bin:"* ]]; then
    echo "✅ Dart tools already in PATH"
else
    echo "📝 Add this to your ~/.bashrc or ~/.zshrc:"
    echo "   export PATH=\"\$PATH:\$HOME/.pub-cache/bin\""
fi

echo ""
echo "✅ Flutter Expert Skill setup complete!"
echo ""
echo "📚 Quick Start:"
echo "   flutter analyze              # Run static analysis"
echo "   dart format lib/ test/       # Check code formatting"
echo "   dcm analyze lib/             # Run code metrics"
echo "   dependency_validator         # Validate dependencies"
echo ""
echo "🔗 Full guide: .github/FLUTTER_EXPERT_GUIDE.md"
echo ""
