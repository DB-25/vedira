#!/bin/sh

# Fail this script if any subcommand fails.
set -e

echo "Starting Flutter setup..."
echo "Current directory: $(pwd)"
echo "CI_WORKSPACE: $CI_WORKSPACE"

# The default execution directory of this script is the ci_scripts directory.
cd $CI_WORKSPACE
echo "Changed to workspace: $(pwd)"

echo "Installing Flutter..."

# Install Flutter using git.
git clone https://github.com/flutter/flutter.git --depth 1 -b stable $HOME/flutter
export PATH="$PATH:$HOME/flutter/bin"

echo "Flutter installed, checking version..."
flutter --version

# Install Flutter artifacts for iOS (--ios), or macOS (--macos) platforms.
echo "Running flutter precache..."
flutter precache --ios

# Install Flutter dependencies from the project root.
echo "Running flutter pub get in project root..."
flutter pub get

# Install CocoaPods using Homebrew.
echo "Installing CocoaPods..."
HOMEBREW_NO_AUTO_UPDATE=1 # disable homebrew's automatic updates.
brew install cocoapods

# Install CocoaPods dependencies.
echo "Running pod install in ios directory..."
cd $CI_WORKSPACE/ios
pod install

echo "Setup complete!"
exit 0 