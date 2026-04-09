#if DEBUG
import Foundation

// MARK: - MockRule Previews

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
#endif
