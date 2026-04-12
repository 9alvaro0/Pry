# Changelog

All notable changes to Pry will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **Tabbed request detail** — Overview, Request, and Response tabs replace the single long scroll. Each tab shows only the relevant information.
- **Summary bar** replaces the filter chip bar — compact display of request count + error/pending indicators. Tapping the filter icon opens the filter sheet.
- **Filter sheet redesign** — clean list-based layout with Status, Sort, Host sections and inline Done/Reset buttons.
- **Pinned requests section** — pinned items appear in a dedicated section at the top of the network list when no status filter is active.
- **Enhanced swipe actions** — leading: Pin + Copy URL + Copy cURL. Trailing: Delete. Each with label and distinct color.
- **Method pill badges** in network rows — colored capsule background using HTTP method colors (GET blue, POST green, etc.).
- **Shared cURL generator** — `NetworkCurlGenerator` extracted as reusable utility.
- **Group by host** — toggle between flat list and domain-grouped view in the Network tab.
- **Headers raw/table toggle** — switch between formatted table and raw text view for request and response headers.
- **Vertical header layout** — key above value for better readability with long header values.
- **New hooks** for Pro extensions — `pryProGlow` (visual theming), `proRulesForEntry` / `proToggleRule` / `proDeleteRule` (inline rule management), `ProToolbarAction.Placement` (contextual action positioning).
- **Console redesign** — terminal-style layout with monospace rows (`HH:mm:ss` timestamp + type label + message), tap-to-expand inline detail, summary bar with error/warning counts, filter sheet matching Network tab design.
- **App Hub standardized rows** — all rows now use consistent layout with title + subtitle below. Every row shows useful context (cookie count, key count, device name, last event, etc.).
- **Settings redesign** — reorganized into Appearance (segmented pickers for trigger and FAB position), Capture (mirror to Xcode, host blacklist), Data (usage summary, clear per type with confirmation), and About (version, author) sections.

### Changed
- **Request detail** — actions (Share, cURL) moved from hidden ellipsis menu to visible toolbar icons and contextual tab buttons.
- **Network row** — increased vertical padding, duration moved to line 2 for more path space.
- **Console rows** — compact terminal style replacing list-based layout. No more NavigationLink push for log detail. Log deletion removed.
- **Sheet header** (`SheetHeader`) — supports pill-style buttons with icon + text label and filled/outline styles.
- **Environment keys** simplified — three Pro override keys replaced by single `pryProGlow: Color?`.
- **Deeplinks and Push colors** — replaced feature-specific colors (purple, yellow) with the app's accent color for consistent identity.
- **Settings Data section** — clear buttons for all 4 data types (Network, Console, Deeplinks, Push) with confirmation alerts, replacing the single "Clear All" button.

### Fixed
- **Console memory leak** — `DateFormatter` was being created on every row render (500 logs = 500 formatters per frame). Now uses a shared static instance.
- **Console performance** — removed unnecessary `.reversed()` call on log array (logs already insert at index 0).

### Removed
- Filter chip bar from the network list top area (replaced by summary bar).
- Pin action from the request detail view (available via list swipe).
- Ellipsis menu from request detail (replaced by toolbar icons and contextual tab buttons).

## [1.0.0] - 2026-04-09

### Added
- **Free SDK public release**. Pry is now an open-core library distributed under MIT.
- `PryStore`, `.pry(store:)` and `.pryEnvironment(store:)` as the entire public API surface.
- `PryContentView` for embedded (tab / sheet) presentation.
- Automatic `URLSession` interception via `URLProtocol` + `URLSessionConfiguration` swizzle. Captures traffic from third-party SDKs (Alamofire, Kingfisher, Firebase, ...) without additional configuration.
- Network monitor with per-entry detail: headers, body, timing breakdown (DNS, TLS, TTFB), redirect chain, JWT decoding, status grouping, host stats.
- GraphQL awareness — detects queries / mutations / subscriptions, extracts operation name and variables, surfaces response errors.
- Inline image preview for `image/*` responses (PNG, JPEG, GIF, WebP).
- Console log stream with `.info` / `.success` / `.warning` / `.error` / `.debug` types, file + function + line metadata, optional mirror to Xcode console.
- Deeplink monitor with automatic `.onOpenURL` capture and a built-in URL simulator.
- Push notification monitor with automatic `UNUserNotificationCenter` delegate interception and a push simulator (APNs payload builder, interruption level, delay, relaunch).
- App Hub: device info, cookies viewer/editor, UserDefaults viewer/editor, permissions dashboard.
- Presentation triggers: floating action button (draggable, side-aware), shake gesture, or both.
- Error badge on the FAB reflecting failed requests.
- Filter chips (Success / Errors / Pending / Pinned) with contextual counts.
- Host blacklist and request pinning, both persisted across launches.
- cURL export for individual requests and full sessions.
- 20 unit tests covering the GraphQL parser.
- `@_spi(PryPro)` hook surface (`PryHooks`, `PryInterceptorHooks`, `PryOverlayModifier`) allowing the Pro SDK to extend Pry without any reverse dependency.

### Changed
- Project renamed from `WarwareInspector` to `Pry`.
- Package directory renamed from `WarwareInspector/` to `pry.dev/Pry/` as part of the open-core split.
- Pro-only features (mock responses, network breakpoints, network throttle, request diff, replay, session export/viewer, protobuf decoding, performance metrics) moved out of this repository into the separate `PryPro` package.

### Removed
- `Pry.unlockPro()`, `Pry.isPro`, `Pry.lockToFree()` and the `FeatureGate` / `ProGateView` runtime feature-gate layer. The new model is compile-time: users import `Pry` for the free feature set or `PryPro` for the full suite, and the UI always matches what was imported.
