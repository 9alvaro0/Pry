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
            authToken: "Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJSUzI1NiJ9...",
            authTokenType: "Bearer",
            authTokenLength: 256,
            duration: 0.43,
            requestSize: 163,
            responseSize: 247
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
            responseSize: 125
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
            responseSize: 98
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
            responseSize: 0
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
            responseSize: 87
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
            responseSize: nil
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
            responseSize: 0
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
            responseSize: 89
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

#endif
