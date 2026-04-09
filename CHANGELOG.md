# Changelog

All notable changes to Pry will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-09

### Added
- **Free SDK public release**. Pry is now an open-core library distributed under MIT.
- `PryStore`, `.pry(store:)` and `.pryEnvironment(store:)` as the entire public API surface.
- `PryContentView` for embedded (tab / sheet) presentation.
- Automatic `URLSession` interception via `URLProtocol` + `URLSessionConfiguration` swizzle. Captures traffic from third-party SDKs (Alamofire, Kingfisher, Firebase, …) without additional configuration.
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
