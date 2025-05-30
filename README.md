# Departures iOS

An iOS application for showing public transit departures from a selected stop/station in Berlin.

## Development Setup

### VSCode / Cursor Setup

1. Open project in XCode once

1. Install [xcode-build-server](https://github.com/SolaWing/xcode-build-server):
   ```bash
   brew install xcode-build-server
   ```

1. Let SourceKit-LSP know about XCode configuration:
   ```bash
   xcode-build-server config -project *.xcodeproj
   ```
   
   This command creates a `buildServer.json` file in your project root that allows SourceKit-LSP to understand your Xcode project configuration, including:
   - Build settings
   - Target configurations
   - Dependencies
   - Module imports

### Set up Firebase

1. Set up a [Firebase](https://firebase.google.com/) project with a [Firestore database](https://firebase.google.com/docs/firestore/quickstart). Make sure not to use the Firebase Studio - create a project and database manually.
2. Get `GoogleService-Info.plist` ([instructions](https://firebase.google.com/docs/ios/setup)) and put it in the project root.

## Building and Running

### Using Xcode

1. Open `Departures.xcodeproj` in Xcode
2. Select your target device or simulator
3. Press `Cmd+R` to build and run

### Using Command Line

```bash
# Build
xcodebuild -project Departures.xcodeproj -scheme Departures -destination 'platform=iOS Simulator,name=iPhone 16'

# Open in the simulator
xcrun simctl launch booted com.bez4pieci.When
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 