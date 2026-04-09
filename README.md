# Pry

**On-device network inspector for iOS.** Like browser DevTools, but inside your app.

Pry intercepts all `URLSession` traffic and gives you a full debugging suite — network monitoring, request editing, mock responses, breakpoints, and more — without leaving the app or connecting to a Mac.

## Features

**Network Inspector**
- Automatic `URLSession` interception (zero-config, no swizzling opt-in needed)
- Request/response detail with headers, body, timing breakdown (DNS, TLS, TTFB)
- GraphQL awareness — detects queries/mutations, shows operation name and variables
- Protobuf raw decoder — decode binary responses without `.proto` schema
- Image response preview — renders PNG/JPEG/GIF/WebP inline
- Search by URL, method, status, host, GraphQL operation name
- Filter chips (Success, Errors, Pending, Pinned) with contextual counts
- Export session as Postman Collection, cURL commands, or HAR archive

**Mock Responses** *(Pro)*
- Create mock rules from any captured request
- Set status code, response body, headers, delay
- Auto-respond without hitting the server

**Network Breakpoints** *(Pro)*
- Pause requests before they reach the server
- Edit URL, method, headers, and body in real time
- Pause responses before they reach your app
- Edit status code and response body
- No recompilation needed

**Request Tools** *(Pro)*
- Replay — re-send any captured request
- Diff — compare two requests side by side
- Network Throttle — simulate Slow 3G, Fast 3G, Lossy, Offline

**Console**
- Structured logging with types (info, success, warning, error, debug)
- Search and filter
- Copy all logs

**App Hub**
- Deeplinks monitor with simulator
- Push Notifications with automatic capture and simulator
- Cookies, UserDefaults editor
- Device & App info, Permissions dashboard
- Performance metrics with live charts *(Pro)*

**Session Sharing** *(Pro)*
- Export entire session as `.pry` file
- Import and view sessions from other devices/teammates
- Read-only viewer with device info banner

**Settings**
- Trigger mode (floating button, shake, or both)
- FAB position (left/right) and draggable mode
- Error badge toggle
- Print-to-console toggle
- Host blacklist
- All preferences persist across app launches

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/9alvaro0/Pry.git", from: "1.0.0")
]
```

Or in Xcode: File > Add Package Dependencies > paste the URL.

## Quick Start

```swift
import Pry

@main
struct MyApp: App {
    @State private var store = PryStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .pry(store: store)
        }
    }
}
```

That's it. A floating ladybug button appears. Tap it to open the inspector.

## Usage

### Trigger Options

```swift
// Floating button (default)
.pry(store: store)

// Shake to open
.pry(store: store, trigger: .shake)

// Both
.pry(store: store, trigger: [.floatingButton, .shake])
```

### Logging

```swift
@Environment(\.pryStore) var pry

pry.log("User logged in", type: .success)
pry.log("Cache miss", type: .warning)
pry.log("Failed to parse", type: .error)
```

### Deeplinks

Deeplinks are captured automatically via `.onOpenURL`. No extra code needed.

### Push Notifications

Push notifications are captured automatically when the inspector starts. No extra code needed.

### Embedded Mode

Use Pry as a tab in your app instead of a floating button:

```swift
TabView {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }

    PryContentView()
        .tabItem { Label("Debug", systemImage: "ladybug") }
}
.environment(\.pryStore, store)
```

### Pro Features

```swift
// Unlock after purchase validation
Pry.unlockPro()

// Check status
if Pry.isPro { ... }

// Lock back (e.g., subscription expired)
Pry.lockToFree()
```

## Requirements

- iOS 18.0+
- Swift 6.0+
- Xcode 16.0+

## How It Works

Pry uses `URLProtocol` with automatic `URLSessionConfiguration` injection to intercept all network traffic — including third-party SDKs like Alamofire, Kingfisher, Firebase, etc. No proxy setup, no certificates, no Mac app needed.

All data stays on-device. Nothing is sent to external servers.

## Architecture

```
Sources/Pry/
  Public/          API surface (PryStore, modifiers, models)
  Internal/        Interceptors, parsers, config (not exposed)
  UI/              SwiftUI views organized by feature
  PreviewContent/  Mock data for Xcode previews
```

## License

TBD

## Author

Alvaro Guerra Freitas — [@9alvaro0](https://github.com/9alvaro0)
