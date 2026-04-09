import Foundation
import Testing
@testable import PryPro

@Suite("MockRule")
struct MockRuleTests {

    // MARK: - Helpers

    private func request(_ url: String, method: String = "GET") -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = method
        return request
    }

    // MARK: - URL Matching

    @Test("Exact URL match succeeds")
    func exactUrlMatch() {
        let rule = MockRule(
            name: "exact",
            urlPattern: "https://api.example.com/v1/users"
        )
        #expect(rule.matches(request("https://api.example.com/v1/users")) == true)
    }

    @Test("Substring URL match succeeds")
    func substringUrlMatch() {
        let rule = MockRule(name: "substring", urlPattern: "/v1/users")
        #expect(rule.matches(request("https://api.example.com/v1/users/42")) == true)
        #expect(rule.matches(request("https://api.example.com/v1/users?active=1")) == true)
    }

    @Test("Non-matching URL returns false")
    func nonMatchingUrl() {
        let rule = MockRule(name: "no-match", urlPattern: "/orders")
        #expect(rule.matches(request("https://api.example.com/v1/users")) == false)
    }

    @Test("Empty URL pattern never matches")
    func emptyPatternNeverMatches() {
        let rule = MockRule(name: "empty", urlPattern: "")
        #expect(rule.matches(request("https://api.example.com/anything")) == false)
    }

    @Test("Pattern matching is case-insensitive")
    func caseInsensitiveMatching() {
        let rule = MockRule(name: "case", urlPattern: "/USERS")
        // localizedCaseInsensitiveContains — upper pattern matches lower URL path.
        #expect(rule.matches(request("https://api.example.com/v1/users")) == true)

        let lowerRule = MockRule(name: "lower", urlPattern: "api.example.com")
        #expect(lowerRule.matches(request("https://API.EXAMPLE.COM/v1/users")) == true)
    }

    // MARK: - Method Matching

    @Test("Nil method matches any HTTP method")
    func nilMethodMatchesAny() {
        let rule = MockRule(name: "any", urlPattern: "/users", method: nil)
        #expect(rule.matches(request("https://api.example.com/users", method: "GET")) == true)
        #expect(rule.matches(request("https://api.example.com/users", method: "POST")) == true)
        #expect(rule.matches(request("https://api.example.com/users", method: "DELETE")) == true)
    }

    @Test("Specific method must match exactly")
    func specificMethodMustMatch() {
        let rule = MockRule(name: "post-only", urlPattern: "/users", method: "POST")
        #expect(rule.matches(request("https://api.example.com/users", method: "POST")) == true)
        #expect(rule.matches(request("https://api.example.com/users", method: "GET")) == false)
    }

    @Test("Method matching is case-insensitive")
    func methodCaseInsensitive() {
        let rule = MockRule(name: "lowercase", urlPattern: "/users", method: "post")
        #expect(rule.matches(request("https://api.example.com/users", method: "POST")) == true)

        let upperRule = MockRule(name: "uppercase", urlPattern: "/users", method: "PUT")
        #expect(upperRule.matches(request("https://api.example.com/users", method: "put")) == true)
    }

    @Test("Empty string method acts like nil — matches any")
    func emptyMethodMatchesAny() {
        // An empty-string method skips the method check (see implementation).
        let rule = MockRule(name: "empty-method", urlPattern: "/users", method: "")
        #expect(rule.matches(request("https://api.example.com/users", method: "GET")) == true)
        #expect(rule.matches(request("https://api.example.com/users", method: "PATCH")) == true)
    }

    // MARK: - isEnabled

    @Test("Disabled rule never matches")
    func disabledRuleNeverMatches() {
        var rule = MockRule(name: "off", urlPattern: "/users")
        rule.isEnabled = false
        #expect(rule.matches(request("https://api.example.com/users")) == false)
    }

    @Test("Re-enabling a previously disabled rule restores matching")
    func reenableRestoresMatching() {
        var rule = MockRule(name: "toggle", urlPattern: "/users")
        rule.isEnabled = false
        #expect(rule.matches(request("https://api.example.com/users")) == false)
        rule.isEnabled = true
        #expect(rule.matches(request("https://api.example.com/users")) == true)
    }

    // MARK: - Edge cases

    @Test("Request with nil URL never matches")
    func nilURLNeverMatches() {
        let rule = MockRule(name: "any", urlPattern: "/users")
        // URLRequest with no URL is the closest thing to a "nil URL" we can build.
        var req = URLRequest(url: URL(string: "about:blank")!)
        req.url = nil
        req.httpMethod = "GET"
        #expect(rule.matches(req) == false)
    }

    @Test("Rule matches when pattern is found in query string")
    func patternMatchesQueryString() {
        let rule = MockRule(name: "query", urlPattern: "active=true")
        #expect(rule.matches(request("https://api.example.com/users?active=true")) == true)
    }

    // MARK: - Parameterized scenarios

    struct MatchCase: Sendable {
        let label: String
        let pattern: String
        let method: String?
        let requestURL: String
        let requestMethod: String
        let expected: Bool
    }

    @Test(
        "Combined URL and method matching scenarios",
        arguments: [
            MatchCase(label: "exact URL + exact method", pattern: "/v1/users", method: "POST", requestURL: "https://api.example.com/v1/users", requestMethod: "POST", expected: true),
            MatchCase(label: "exact URL + wrong method", pattern: "/v1/users", method: "POST", requestURL: "https://api.example.com/v1/users", requestMethod: "GET", expected: false),
            MatchCase(label: "substring URL + any method", pattern: "example.com", method: nil, requestURL: "https://api.example.com/v1/users", requestMethod: "DELETE", expected: true),
            MatchCase(label: "no match at all", pattern: "/orders", method: "POST", requestURL: "https://api.example.com/v1/users", requestMethod: "POST", expected: false),
            MatchCase(label: "case-insensitive host", pattern: "API.EXAMPLE.COM", method: nil, requestURL: "https://api.example.com/v1/users", requestMethod: "GET", expected: true),
        ]
    )
    func parameterizedMatchScenarios(_ scenario: MatchCase) {
        let rule = MockRule(name: scenario.label, urlPattern: scenario.pattern, method: scenario.method)
        var req = URLRequest(url: URL(string: scenario.requestURL)!)
        req.httpMethod = scenario.requestMethod
        #expect(rule.matches(req) == scenario.expected, "scenario: \(scenario.label)")
    }

    // MARK: - Codable round-trip

    @Test("MockRule round-trips through JSON Codable")
    func codableRoundTrip() throws {
        let original = MockRule(
            name: "Unit test",
            urlPattern: "/api/foo",
            method: "GET",
            statusCode: 418,
            responseBody: #"{"teapot":true}"#,
            responseHeaders: ["Content-Type": "application/json"],
            delay: 0.25
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        let data = try encoder.encode(original)
        let decoded = try decoder.decode(MockRule.self, from: data)

        #expect(decoded.id == original.id)
        #expect(decoded.name == original.name)
        #expect(decoded.urlPattern == original.urlPattern)
        #expect(decoded.method == original.method)
        #expect(decoded.statusCode == original.statusCode)
        #expect(decoded.responseBody == original.responseBody)
        #expect(decoded.responseHeaders == original.responseHeaders)
        #expect(decoded.delay == original.delay)
        #expect(decoded.isEnabled == original.isEnabled)
    }
}
