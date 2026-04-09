import Foundation
import Testing
@testable import Pry

@Suite("GraphQLParser")
struct GraphQLParserTests {

    // MARK: - Valid Request Parsing

    @Test("Parses named query with operationName and variables")
    func parsesNamedQueryWithVariables() throws {
        let body = #"""
        {"query":"query GetUser($id: ID!) { user(id: $id) { id name } }","operationName":"GetUser","variables":{"id":"42"}}
        """#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.operationType == .query)
        #expect(info.operationName == "GetUser")
        #expect(info.query.contains("query GetUser"))
        let variables = try #require(info.variables)
        #expect(variables.contains("\"id\""))
        #expect(variables.contains("\"42\""))
        #expect(info.hasErrors == false)
        #expect(info.errors.isEmpty)
    }

    @Test("Parses anonymous query starting with brace")
    func parsesAnonymousQuery() throws {
        let body = #"{"query":"{ user { id } }"}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.operationType == .query)
        #expect(info.operationName == nil)
        #expect(info.variables == nil)
    }

    @Test("Detects operation name from inline named query syntax")
    func namedQueryInlineSyntax() throws {
        let body = #"{"query":"query GetUser { user { id name } }"}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.operationType == .query)
        #expect(info.operationName == "GetUser")
    }

    @Test("Detects mutation operation type")
    func detectsMutation() throws {
        let body = #"{"query":"mutation CreatePost($input: PostInput!) { createPost(input: $input) { id } }","variables":{"input":{"title":"Hello"}}}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.operationType == .mutation)
        #expect(info.operationName == "CreatePost")
    }

    @Test("Detects subscription operation type")
    func detectsSubscription() throws {
        let body = #"{"query":"subscription OnMessage { messageAdded { id text } }"}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.operationType == .subscription)
        #expect(info.operationName == "OnMessage")
    }

    @Test("Extracts operation name from multi-line query with real newlines")
    func operationNameFromMultiLineQuery() throws {
        // Mimics the countries.trevorblades.com GetCountry query — the body arrives as
        // a JSON string containing actual line breaks inside the query field.
        let body = #"{"query":"query GetCountry($code: ID!) {\n  country(code: $code) {\n    name\n    capital\n    currency\n  }\n}","operationName":"GetCountry","variables":{"code":"BR"}}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://countries.trevorblades.com/",
                responseBody: nil
            )
        )

        #expect(info.operationType == .query)
        #expect(info.operationName == "GetCountry")
        #expect(info.query.contains("\n"))
    }

    @Test("Falls back to query-text extraction when operationName is missing")
    func fallsBackToQueryTextExtraction() throws {
        let body = #"{"query":"query FetchTodos {\n  todos { id }\n}"}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.operationName == "FetchTodos")
    }

    // MARK: - Non-GraphQL Bodies

    @Test("Returns nil for JSON body without a query field")
    func returnsNilForNonGraphQLJSON() {
        let body = #"{"name":"John","age":30}"#
        #expect(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/users",
                responseBody: nil
            ) == nil
        )
    }

    @Test("Returns nil for non-JSON request body")
    func returnsNilForNonJSON() {
        let body = "this is not json at all"
        #expect(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            ) == nil
        )
    }

    @Test("Returns nil for nil request body")
    func returnsNilForNilBody() {
        #expect(
            GraphQLParser.parse(
                requestBody: nil,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            ) == nil
        )
    }

    @Test("Returns nil for empty request body")
    func returnsNilForEmptyBody() {
        #expect(
            GraphQLParser.parse(
                requestBody: "",
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            ) == nil
        )
    }

    @Test("Returns nil when JSON top-level is an array")
    func returnsNilForTopLevelArray() {
        let body = #"[{"query":"{ ping }"}]"#
        #expect(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            ) == nil
        )
    }

    // MARK: - Response Errors

    @Test("Parses response errors with message and path")
    func parsesResponseErrors() throws {
        let body = #"{"query":"{ user { id } }"}"#
        let responseBody = """
        {
          "data": null,
          "errors": [
            {"message": "User not found", "path": ["user"]},
            {"message": "Forbidden", "path": ["user", "email"]}
          ]
        }
        """

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: responseBody
            )
        )

        #expect(info.hasErrors == true)
        #expect(info.errors.count == 2)
        #expect(info.errors[0].message == "User not found")
        #expect(info.errors[0].path == "user")
        #expect(info.errors[1].message == "Forbidden")
        #expect(info.errors[1].path == "user.email")
    }

    @Test("Reports no errors for successful response")
    func noErrorsForSuccessfulResponse() throws {
        let body = #"{"query":"{ user { id } }"}"#
        let responseBody = #"{"data":{"user":{"id":"1"}}}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: responseBody
            )
        )

        #expect(info.hasErrors == false)
        #expect(info.errors.isEmpty)
    }

    @Test("Reports no errors when response body is nil")
    func noErrorsForNilResponse() throws {
        let body = #"{"query":"{ user { id } }"}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(info.hasErrors == false)
    }

    @Test("Ignores error entries that are missing the message field")
    func skipsErrorsWithoutMessage() throws {
        let body = #"{"query":"{ user { id } }"}"#
        let responseBody = #"{"errors":[{"path":["user"]},{"message":"Real error"}]}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: responseBody
            )
        )

        #expect(info.hasErrors == true)
        #expect(info.errors.count == 1)
        #expect(info.errors[0].message == "Real error")
    }

    @Test("Handles non-JSON response body without crashing")
    func nonJSONResponseBodyIsSafe() throws {
        let body = #"{"query":"{ user { id } }"}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: "<html>Server Error</html>"
            )
        )

        #expect(info.hasErrors == false)
        #expect(info.errors.isEmpty)
    }

    // MARK: - Variables Formatting

    @Test("Formats variables dictionary as pretty-printed JSON")
    func formatsVariablesAsJSON() throws {
        let body = #"{"query":"query GetUser($id: ID!) { user(id: $id) { id } }","variables":{"id":"42","active":true}}"#

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        let variables = try #require(info.variables)
        // Pretty-printed output always contains a newline and indentation.
        #expect(variables.contains("\n"))
        #expect(variables.contains("\"id\""))
        #expect(variables.contains("\"42\""))
        #expect(variables.contains("\"active\""))
        // Sorted keys — "active" must appear before "id".
        let activeIdx = try #require(variables.range(of: "\"active\""))
        let idIdx = try #require(variables.range(of: "\"id\""))
        #expect(activeIdx.lowerBound < idIdx.lowerBound)
    }

    @Test("Variables is nil when absent, null, or empty dict")
    func variablesIsNilForEmptyCases() throws {
        let cases: [String] = [
            #"{"query":"{ user { id } }"}"#,
            #"{"query":"{ user { id } }","variables":null}"#,
            #"{"query":"{ user { id } }","variables":{}}"#,
        ]
        for body in cases {
            let info = try #require(
                GraphQLParser.parse(
                    requestBody: body,
                    requestURL: "https://api.example.com/graphql",
                    responseBody: nil
                )
            )
            #expect(info.variables == nil, "variables should be nil for body: \(body)")
        }
    }

    // MARK: - Parameterized Operation Type Detection

    struct OperationCase: Sendable {
        let query: String
        let expected: GraphQLInfo.OperationType
        let description: String
    }

    @Test(
        "Detects operation type from query prefix",
        arguments: [
            OperationCase(query: "query Foo { a }", expected: .query, description: "named query"),
            OperationCase(query: "mutation Bar { a }", expected: .mutation, description: "named mutation"),
            OperationCase(query: "subscription Baz { a }", expected: .subscription, description: "named subscription"),
            OperationCase(query: "{ a }", expected: .query, description: "anonymous shorthand"),
            OperationCase(query: "   mutation Leading { a }", expected: .mutation, description: "leading whitespace mutation"),
        ]
    )
    func detectsOperationTypeFromPrefix(_ testCase: OperationCase) throws {
        let escaped = testCase.query
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
        let body = "{\"query\":\"\(escaped)\"}"

        let info = try #require(
            GraphQLParser.parse(
                requestBody: body,
                requestURL: "https://api.example.com/graphql",
                responseBody: nil
            )
        )

        #expect(
            info.operationType == testCase.expected,
            "expected \(testCase.expected) for \(testCase.description)"
        )
    }
}
