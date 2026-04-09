# Pry

**On-device network inspector for iOS.** Like browser DevTools, but inside your app.

Pry intercepts all `URLSession` traffic and gives you a full debugging suite — network monitoring, request/response inspection, structured logging, deeplinks, push notifications and more — without leaving the app or connecting to a Mac.

Zero dependencies, zero configuration. Add one modifier and you are done.

## Features

**Network Inspector**
- Automatic `URLSession` interception, including third-party SDKs (Alamofire, Kingfisher, Firebase, …)
- Request / response detail with headers, body, status, timing breakdown (DNS, TLS, TTFB)
- GraphQL awareness — detects queries/mutations, shows operation name and variables
- Image response preview — renders PNG / JPEG / GIF / WebP inline
- Redirect chain visualization
- Search by URL, method, status, host, GraphQL operation name
- Filter chips (Success, Errors, Pending, Pinned) with contextual counts
- Export session as cURL commands
- Pin / blacklist hosts
- Per-host network stats

**Console**
- Structured logging with types (info, success, warning, error, debug)
- File / function / line metadata captured automatically
- Search and filter
- Mirror to Xcode console (toggle)

**App Hub**
- Deeplinks monitor with URL builder simulator
- Push Notifications with automatic capture and simulator
- Cookies viewer / editor
- UserDefaults viewer / editor
- Device & App info
- Permissions dashboard

**Presentation & Controls**
- Floating action button, shake gesture, or both
- FAB position (left / right) and draggable mode
- Error count badge on the FAB
- Embedded mode — use Pry as a tab in your own app
- All preferences persist across launches

## Installation

### Swift Package Manager

```swift
dependencies: [
    .package(url: "https://github.com/9alvaro0/Pry.git", from: "1.0.0")
]
```

Or in Xcode: **File → Add Package Dependencies…** and paste the URL.

## Quick Start

```swift
import SwiftUI
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

That is it. A floating ladybug button appears on top of your app. Tap it to open the inspector.

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
struct MyView: View {
    @Environment(\.pryStore) private var pry

    var body: some View {
        Button("Sign in") {
            pry.log("User tapped sign in", type: .info)
        }
    }
}
```

Available log types: `.info`, `.success`, `.warning`, `.error`, `.debug`.

### Deeplinks

Deeplinks are captured automatically — Pry installs an `.onOpenURL` handler on the view you attach `.pry(store:)` to. No extra code needed.

### Push Notifications

Push notifications received while the app is running are captured automatically. No extra code needed.

### Embedded Mode

If you do not want a floating button and prefer a dedicated tab:

```swift
TabView {
    HomeView()
        .tabItem { Label("Home", systemImage: "house") }

    PryContentView()
        .tabItem { Label("Debug", systemImage: "ladybug") }
}
.pryEnvironment(store: store)
```

`.pryEnvironment(store:)` injects the store without adding any UI chrome.

### Store Configuration

```swift
PryStore(
    maxNetworkEntries: 200, // default
    maxLogEntries: 500,     // default
    maxDeeplinkEntries: 100,
    maxPushEntries: 100
)
```

Blacklist hosts you never want to capture:

```swift
store.blacklistedHosts.insert("telemetry.myservice.com")
```

## Requirements

- iOS 18.0+
- Swift 6.0+
- Xcode 16.0+

## How It Works

Pry uses `URLProtocol` with automatic `URLSessionConfiguration` injection to intercept every `URLSession` created by your app (including third-party libraries). No proxy setup, no certificates, no Mac app. Everything runs on-device.

All captured data stays on-device. Nothing is ever sent to external servers.

## Architecture

```
Sources/Pry/
  Public/           API surface (PryStore, modifiers, models)
  Internal/         Interceptors, parsers, config (not exposed)
  UI/               SwiftUI views organized by feature
  PreviewContent/   Mock data for Xcode previews
```

## License

MIT — see [LICENSE](LICENSE).

## Author

Alvaro Guerra Freitas — [@9alvaro0](https://github.com/9alvaro0)
