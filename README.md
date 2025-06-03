<img src="Documentation/Icon@2x.png" width=100><br>

# When? (iOS)

An iOS application for showing public transit departures from a selected stop/station in Berlin.

## Install

📲 [Install from the App Store](https://apps.apple.com/de/app/when-berlin/id6746681074)

## Architecture

- iOS App: Swift, SwiftData, SwiftUI
- Firebase Firestore for storing live activities while they're active
- Firebase Cloud functions ([bez4pieci/When-App-API](https://github.com/bez4pieci/When-App-API)) for updating the live activities via push notifications
- Public transport API
   - [alexander-albers/tripkit](https://github.com/alexander-albers/tripkit) for iOS
   - [public-transport/hafas-client](https://github.com/public-transport/hafas-client) for the Node.js cloud function


## Build From Source

1. Check out the code and `cd` to the project root
1. Set up [Firebase](https://firebase.google.com/):
   1. Create a new project
   1. Add an iOS app ([instructions](https://firebase.google.com/docs/ios/setup#prerequisites))
      - Use `com.bez4pieci.When` as bundle id
      - Leave optional fields blank
      - 👉 Download `GoogleService-Info.plist` and put it in the project root
   1. Create a new [Firestore database](https://firebase.google.com/docs/firestore/quickstart). You don't need to do anything beyond just creating it.
1. Open the project in XCode
1. Build with XCode

## Develop

### VSCode / Cursor Setup

1. Make sure to open the project in XCoce at least once. This will create the necessary XCode project configuration on your computer.

1. Install [xcode-build-server](https://github.com/SolaWing/xcode-build-server):
   ```bash
   brew install xcode-build-server
   ```

1. Let SourceKit-LSP know about XCode configuration:
   ```bash
   cd <project root>
   xcode-build-server config -project *.xcodeproj
   ```
   
   This command creates a `buildServer.json` file in your project root that allows SourceKit-LSP to understand your Xcode project configuration, including:
   - Build settings
   - Target configurations
   - Dependencies
   - Module imports

### Build Using Command Line

```bash
# Build
xcodebuild -project Departures.xcodeproj -scheme Departures -destination 'platform=iOS Simulator,name=iPhone 16'

# Open in the simulator
xcrun simctl launch booted com.bez4pieci.When
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details. 