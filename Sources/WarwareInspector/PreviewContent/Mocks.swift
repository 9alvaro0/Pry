#if DEBUG
import Foundation

// MARK: - NetworkEntry Mocks

extension NetworkEntry {

    static var mockSuccess: NetworkEntry {
        NetworkEntry(
            timestamp: Date(),
            type: .network,
            requestURL: "https://api.example.com/v1/users",
            requestMethod: "POST",
            requestHeaders: [
                "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiI...",
                "Content-Type": "application/json",
                "User-Agent": "iOS App/1.0"
            ],
            requestBody: """
            {
              "filters": {
                "page": 1,
                "size": 20
              }
            }
            """,
            responseStatusCode: 200,
            responseHeaders: [
                "Content-Type": "application/json",
                "Date": "Mon, 02 Dec 2024 10:30:45 GMT"
            ],
            responseBody: """
            {
              "data": [
                {
                  "id": 123,
                  "title": "Sample Item",
                  "status": "active"
                }
              ]
            }
            """,
            responseError: nil,
            // Real decodable JWT: {"sub":"user123","iss":"auth.example.com","iat":1712500000,"exp":9999999999,"name":"John Doe","role":"admin"}
            authToken: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJ1c2VyMTIzIiwiaXNzIjoiYXV0aC5leGFtcGxlLmNvbSIsImlhdCI6MTcxMjUwMDAwMCwiZXhwIjo5OTk5OTk5OTk5LCJuYW1lIjoiSm9obiBEb2UiLCJyb2xlIjoiYWRtaW4ifQ.mock-signature",
            authTokenType: "Bearer",
            authTokenLength: 186,
            duration: 0.43,
            requestSize: 163,
            responseSize: 247,
            metrics: TimingMetrics(
                dnsLookup: 0.012,
                tcpConnect: 0.025,
                tlsHandshake: 0.045,
                requestSent: 0.002,
                waitingForResponse: 0.280,
                responseReceived: 0.066,
                total: 0.430
            )
        )
    }

    static var mockError: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-60),
            type: .network,
            requestURL: "https://api.example.com/v1/users/123",
            requestMethod: "GET",
            requestHeaders: [
                "Accept": "application/json",
                "User-Agent": "iOS App/1.0"
            ],
            requestBody: nil,
            responseStatusCode: 404,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: """
            {
              "error": {
                "code": "RESOURCE_NOT_FOUND",
                "description": "Resource not found"
              }
            }
            """,
            responseError: "Resource not found",
            authToken: nil,
            authTokenType: nil,
            authTokenLength: nil,
            duration: 1.2,
            requestSize: nil,
            responseSize: 125,
            metrics: nil
        )
    }

    static var mockServerError: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-45),
            type: .network,
            requestURL: "https://api.example.com/v1/orders",
            requestMethod: "POST",
            requestHeaders: [
                "Authorization": "Bearer eyJ0eXAiOiJKV1Qi...",
                "Content-Type": "application/json"
            ],
            requestBody: """
            {
              "productId": "ABC-123",
              "quantity": 2
            }
            """,
            responseStatusCode: 500,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: """
            {
              "error": {
                "message": "Internal server error",
                "code": "INTERNAL_ERROR"
              }
            }
            """,
            responseError: "Internal server error",
            authToken: "Bearer eyJ0eXAiOiJKV1Qi...",
            authTokenType: "Bearer",
            authTokenLength: 180,
            duration: 3.45,
            requestSize: 52,
            responseSize: 98,
            metrics: nil
        )
    }

    static var mockNotification: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-120),
            type: .network,
            requestURL: "https://api.example.com/v1/notifications",
            requestMethod: "POST",
            requestHeaders: [
                "Authorization": "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiI...",
                "Content-Type": "application/json"
            ],
            requestBody: """
            {
              "token": "sample-token",
              "device": "sample-device-id",
              "platform": "ios"
            }
            """,
            responseStatusCode: 204,
            responseHeaders: ["Content-Length": "0"],
            responseBody: nil,
            responseError: nil,
            authToken: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
            authTokenType: "Bearer",
            authTokenLength: 256,
            duration: 0.18,
            requestSize: 202,
            responseSize: 0,
            metrics: nil
        )
    }

    static var mockNoAuth: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-30),
            type: .network,
            requestURL: "https://api.example.com/v1/health",
            requestMethod: "GET",
            requestHeaders: [
                "Accept": "application/json",
                "User-Agent": "iOS App/1.0"
            ],
            requestBody: nil,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: """
            {
              "status": "ok"
            }
            """,
            responseError: nil,
            authToken: nil,
            authTokenType: nil,
            authTokenLength: nil,
            duration: 0.08,
            requestSize: nil,
            responseSize: 87,
            metrics: nil
        )
    }

    static var mockPending: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-2),
            type: .network,
            requestURL: "https://api.example.com/v1/upload",
            requestMethod: "PUT",
            requestHeaders: [
                "Content-Type": "multipart/form-data",
                "Authorization": "Bearer eyJ0eXAi..."
            ],
            requestBody: "[Binary data: 2.4MB]",
            responseStatusCode: nil,
            responseHeaders: nil,
            responseBody: nil,
            responseError: nil,
            authToken: "Bearer eyJ0eXAi...",
            authTokenType: "Bearer",
            authTokenLength: 140,
            duration: nil,
            requestSize: 2_400_000,
            responseSize: nil,
            metrics: nil
        )
    }

    static var mockDelete: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-90),
            type: .network,
            requestURL: "https://api.example.com/v1/users/456/sessions",
            requestMethod: "DELETE",
            requestHeaders: [
                "Authorization": "Bearer eyJ0eXAi...",
                "Accept": "application/json"
            ],
            requestBody: nil,
            responseStatusCode: 204,
            responseHeaders: [:],
            responseBody: nil,
            responseError: nil,
            authToken: "Bearer eyJ0eXAi...",
            authTokenType: "Bearer",
            authTokenLength: 140,
            duration: 0.31,
            requestSize: nil,
            responseSize: 0,
            metrics: nil
        )
    }

    static var mockPatch: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-15),
            type: .network,
            requestURL: "https://api.example.com/v1/users/me/settings",
            requestMethod: "PATCH",
            requestHeaders: [
                "Authorization": "Bearer eyJ0eXAi...",
                "Content-Type": "application/json"
            ],
            requestBody: """
            {
              "darkMode": true,
              "language": "es"
            }
            """,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: """
            {
              "darkMode": true,
              "language": "es",
              "updatedAt": "2026-04-07T18:30:00Z"
            }
            """,
            responseError: nil,
            authToken: "Bearer eyJ0eXAi...",
            authTokenType: "Bearer",
            authTokenLength: 140,
            duration: 0.22,
            requestSize: 42,
            responseSize: 89,
            metrics: nil
        )
    }
}

// MARK: - LogEntry Mocks

extension LogEntry {

    static var mockInfo: LogEntry {
        LogEntry(
            timestamp: Date(),
            type: .info,
            message: "App launched successfully",
            file: "AppDelegate.swift",
            function: "didFinishLaunching()",
            line: 42,
            additionalInfo: nil
        )
    }

    static var mockSuccess: LogEntry {
        LogEntry(
            timestamp: Date().addingTimeInterval(-5),
            type: .success,
            message: "User authenticated with OAuth2",
            file: "AuthService.swift",
            function: "login()",
            line: 88,
            additionalInfo: nil
        )
    }

    static var mockWarning: LogEntry {
        LogEntry(
            timestamp: Date().addingTimeInterval(-10),
            type: .warning,
            message: "Cache expired, fetching fresh data from server",
            file: "CacheManager.swift",
            function: "validateCache()",
            line: 156,
            additionalInfo: nil
        )
    }

    static var mockError: LogEntry {
        LogEntry(
            timestamp: Date().addingTimeInterval(-15),
            type: .error,
            message: "Failed to decode UserProfile: keyNotFound(\"avatar\", codingPath: [\"data\", \"user\"])",
            file: "UserRepository.swift",
            function: "fetchProfile()",
            line: 73,
            additionalInfo: nil
        )
    }

    static var mockDebug: LogEntry {
        LogEntry(
            timestamp: Date().addingTimeInterval(-20),
            type: .debug,
            message: "URLSession config: timeout=30s, cache=useProtocolCachePolicy, cellular=true",
            file: "NetworkClient.swift",
            function: "configure()",
            line: 22,
            additionalInfo: nil
        )
    }

    static var mockNetwork: LogEntry {
        LogEntry(
            timestamp: Date().addingTimeInterval(-3),
            type: .network,
            message: "GET /v1/users -> 200 (430ms)",
            file: "NetworkLogger.swift",
            function: "logResponse()",
            line: 91,
            additionalInfo: nil
        )
    }
}

// MARK: - DeeplinkEntry Mocks

extension DeeplinkEntry {

    static var mockCustomScheme: DeeplinkEntry {
        DeeplinkEntry(
            timestamp: Date(),
            url: "myapp://rooms/open?roomId=42&floor=3",
            scheme: "myapp",
            host: "rooms",
            path: "/open",
            pathComponents: ["open"],
            queryParameters: [
                .init(name: "roomId", value: "42"),
                .init(name: "floor", value: "3")
            ],
            fragment: nil
        )
    }

    static var mockUniversalLink: DeeplinkEntry {
        DeeplinkEntry(
            timestamp: Date().addingTimeInterval(-30),
            url: "https://app.example.com/booking/confirm/789?ref=push&source=notification",
            scheme: "https",
            host: "app.example.com",
            path: "/booking/confirm/789",
            pathComponents: ["booking", "confirm", "789"],
            queryParameters: [
                .init(name: "ref", value: "push"),
                .init(name: "source", value: "notification")
            ],
            fragment: nil
        )
    }

    static var mockWidgetLink: DeeplinkEntry {
        DeeplinkEntry(
            timestamp: Date().addingTimeInterval(-60),
            url: "myapp://widget/quick-action?action=newTask",
            scheme: "myapp",
            host: "widget",
            path: "/quick-action",
            pathComponents: ["quick-action"],
            queryParameters: [
                .init(name: "action", value: "newTask")
            ],
            fragment: nil
        )
    }
}

// MARK: - CodeBlock / JSON Mocks

enum MockJSON {

    static let simple = """
    {
      "status": "ok",
      "version": "1.2.3"
    }
    """

    static let nested = """
    {
      "data": [
        {
          "id": 123,
          "title": "Sample Item",
          "status": "active",
          "metadata": {
            "created": "2026-04-07",
            "tags": ["swift", "ios", "network"]
          }
        },
        {
          "id": 456,
          "title": "Another Item",
          "status": "archived",
          "metadata": null
        }
      ],
      "pagination": {
        "page": 1,
        "total": 42,
        "hasNext": true
      }
    }
    """

    static let allTypes = """
    {
      "string": "hello world",
      "number": 42,
      "decimal": 3.14,
      "boolTrue": true,
      "boolFalse": false,
      "nullValue": null,
      "array": [1, 2, 3],
      "nested": {
        "key": "value"
      }
    }
    """

    static let deepNesting = """
    {
      "level1": {
        "level2": {
          "level3": {
            "level4": {
              "level5": {
                "deep": "value"
              }
            }
          }
        }
      }
    }
    """

    static let largeArray = """
    {
      "items": [
        {"id": 1, "name": "Item 1"},
        {"id": 2, "name": "Item 2"},
        {"id": 3, "name": "Item 3"},
        {"id": 4, "name": "Item 4"},
        {"id": 5, "name": "Item 5"}
      ]
    }
    """

    static let emptyStructures = """
    {
      "emptyObject": {},
      "emptyArray": [],
      "emptyString": ""
    }
    """

    static let trailingCommas = """
    {
      "name": "test",
      "value": 42,
    }
    """

    static let invalid = "{ broken json: not valid ["
}

enum MockHTTP {

    static let postRequest = """
    POST /v1/bookings/filter HTTP/1.1
    Host: api.example.com
    Authorization: Bearer eyJ0eXAiOiJKV1Qi...
    Content-Type: application/json
    Accept: */*
    User-Agent: MyApp/2.1
    """

    static let getMinimal = """
    GET /health HTTP/1.1
    Host: api.example.com
    """
}

enum MockText {

    static let short = "Simple response: everything is working correctly."

    static let long = (1...25).map {
        "Log line \($0): Processing request with id=\($0 * 1000 + 42)"
    }.joined(separator: "\n")
}

enum MockForm {

    static let simple = "name=John+Doe&email=john%40example.com&age=30"

    static let oauth = "grant_type=authorization_code&code=abc123&redirect_uri=https%3A%2F%2Fapp.example.com%2Fcallback&client_id=my-app"
}

// MARK: - Network Mocks with Form/Image bodies

extension NetworkEntry {

    static var mockRedirect: NetworkEntry {
        var entry = NetworkEntry(
            timestamp: Date().addingTimeInterval(-7),
            type: .network,
            requestURL: "https://api.example.com/v1/legacy/users",
            requestMethod: "GET",
            requestHeaders: ["Accept": "application/json"],
            requestBody: nil,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: """
            {
              "users": []
            }
            """,
            responseError: nil,
            authToken: nil,
            authTokenType: nil,
            authTokenLength: nil,
            duration: 0.95,
            requestSize: nil,
            responseSize: 42,
            metrics: NetworkEntry.TimingMetrics(
                dnsLookup: 0.008,
                tcpConnect: 0.018,
                tlsHandshake: 0.035,
                requestSent: 0.001,
                waitingForResponse: 0.850,
                responseReceived: 0.038,
                total: 0.950
            )
        )
        entry.redirectCount = 2
        return entry
    }

    static var mockFormPost: NetworkEntry {
        NetworkEntry(
            timestamp: Date().addingTimeInterval(-10),
            type: .network,
            requestURL: "https://auth.example.com/oauth/token",
            requestMethod: "POST",
            requestHeaders: [
                "Content-Type": "application/x-www-form-urlencoded",
                "Accept": "application/json"
            ],
            requestBody: MockForm.oauth,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: """
            {
              "access_token": "eyJ0eXAiOiJKV1Qi...",
              "token_type": "Bearer",
              "expires_in": 3600
            }
            """,
            responseError: nil,
            authToken: nil,
            authTokenType: nil,
            authTokenLength: nil,
            duration: 0.55,
            requestSize: 120,
            responseSize: 95,
            metrics: nil
        )
    }
}

// MARK: - PushNotificationEntry Mocks

extension PushNotificationEntry {

    static var mockPromo: PushNotificationEntry {
        PushNotificationEntry(
            timestamp: Date(),
            title: "Flash Sale!",
            body: "50% off all items for the next 2 hours. Don't miss out!",
            subtitle: "Limited Time Offer",
            badge: 3,
            sound: "default",
            categoryIdentifier: "PROMO",
            threadIdentifier: "marketing",
            userInfo: ["deeplink": "myapp://sale/flash", "campaign_id": "summer2026"],
            rawPayload: """
            {
              "aps": {
                "alert": {
                  "title": "Flash Sale!",
                  "body": "50% off all items for the next 2 hours.",
                  "subtitle": "Limited Time Offer"
                },
                "badge": 3,
                "sound": "default",
                "category": "PROMO",
                "thread-id": "marketing"
              },
              "deeplink": "myapp://sale/flash",
              "campaign_id": "summer2026"
            }
            """
        )
    }

    static var mockChat: PushNotificationEntry {
        PushNotificationEntry(
            timestamp: Date().addingTimeInterval(-120),
            title: "New Message",
            body: "Hey, are you coming to the meeting?",
            subtitle: nil,
            badge: 1,
            sound: "message.caf",
            categoryIdentifier: "CHAT",
            threadIdentifier: "chat-room-42",
            userInfo: ["sender_id": "user456", "room_id": "42"],
            rawPayload: """
            {
              "aps": {
                "alert": {
                  "title": "New Message",
                  "body": "Hey, are you coming to the meeting?"
                },
                "badge": 1,
                "sound": "message.caf"
              },
              "sender_id": "user456",
              "room_id": "42"
            }
            """
        )
    }

    static var mockSilent: PushNotificationEntry {
        PushNotificationEntry(
            timestamp: Date().addingTimeInterval(-300),
            title: nil,
            body: nil,
            subtitle: nil,
            badge: nil,
            sound: nil,
            categoryIdentifier: "BACKGROUND_SYNC",
            threadIdentifier: nil,
            userInfo: ["content-available": "1", "sync_type": "incremental"],
            rawPayload: """
            {
              "aps": {
                "content-available": 1
              },
              "sync_type": "incremental"
            }
            """
        )
    }
}

// MARK: - MockRule Mocks

extension MockRule {

    static var mockUsersSuccess: MockRule {
        MockRule(
            name: "Users - Success",
            urlPattern: "/api/users",
            method: "GET",
            statusCode: 200,
            responseBody: "{\"users\": [{\"id\": 1, \"name\": \"John\"}]}",
            responseHeaders: ["Content-Type": "application/json"],
            delay: 0
        )
    }

    static var mockCartError: MockRule {
        MockRule(
            name: "Cart - Server Error",
            urlPattern: "/api/cart",
            method: "POST",
            statusCode: 500,
            responseBody: "{\"error\": \"Internal server error\"}",
            responseHeaders: ["Content-Type": "application/json"],
            delay: 0.5
        )
    }
}

// MARK: - Mocked NetworkEntry

extension NetworkEntry {

    static var mockMocked: NetworkEntry {
        var entry = NetworkEntry(
            timestamp: Date().addingTimeInterval(-5),
            type: .network,
            requestURL: "https://api.example.com/api/users",
            requestMethod: "GET",
            requestHeaders: [
                "Accept": "application/json",
                "User-Agent": "iOS App/1.0"
            ],
            requestBody: nil,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: "{\"users\": [{\"id\": 1, \"name\": \"John\"}]}",
            responseError: nil,
            authToken: nil,
            authTokenType: nil,
            authTokenLength: nil,
            duration: 0.01,
            requestSize: nil,
            responseSize: 48,
            metrics: nil
        )
        entry.isMocked = true
        return entry
    }
}

// MARK: - Replayed NetworkEntry

extension NetworkEntry {

    static var mockReplay: NetworkEntry {
        var entry = NetworkEntry(
            timestamp: Date().addingTimeInterval(-2),
            type: .network,
            requestURL: "https://api.example.com/api/users/42",
            requestMethod: "GET",
            requestHeaders: [
                "Accept": "application/json",
                "Authorization": "Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc"
            ],
            requestBody: nil,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: "{\n  \"id\": 42,\n  \"name\": \"Jane Doe\",\n  \"email\": \"jane@example.com\"\n}",
            responseError: nil,
            authToken: "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxIn0.abc",
            authTokenType: "Bearer Token",
            authTokenLength: 48,
            duration: 0.187,
            requestSize: nil,
            responseSize: 72,
            metrics: nil
        )
        entry.isReplay = true
        return entry
    }
}

#endif
