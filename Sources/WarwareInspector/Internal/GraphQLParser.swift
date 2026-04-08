import Foundation
import SwiftUI

/// Parsed GraphQL operation info extracted from a network request.
struct GraphQLInfo: Sendable {

    enum OperationType: String, Sendable {
        case query = "Query"
        case mutation = "Mutation"
        case subscription = "Subscription"

        var color: Color {
            self == .mutation ? InspectorTheme.Colors.warning : InspectorTheme.Colors.syntaxString
        }
    }

    let operationType: OperationType
    let operationName: String?
    let query: String
    let variables: String? // Pretty-printed JSON
    let hasErrors: Bool
    let errors: [GraphQLError]

    struct GraphQLError: Sendable {
        let message: String
        let path: String?
    }
}

/// Parses GraphQL requests and responses from network entry data.
enum GraphQLParser {

    /// Attempts to parse GraphQL info from a network entry's request body.
    /// Returns nil if this is not a GraphQL request.
    static func parse(requestBody: String?, requestURL: String, responseBody: String?) -> GraphQLInfo? {
        // GraphQL requests are typically POST to a path containing "graphql"
        guard let body = requestBody,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let query = json["query"] as? String else {
            return nil
        }

        // Also check URL heuristic — some APIs don't use /graphql path
        // but if we have a "query" field in the body, it's likely GraphQL
        let operationType = detectOperationType(from: query)
        let operationName = (json["operationName"] as? String) ?? extractOperationName(from: query)
        let variables = formatVariables(json["variables"])

        // Parse response errors
        let (hasErrors, errors) = parseResponseErrors(responseBody)

        return GraphQLInfo(
            operationType: operationType,
            operationName: operationName,
            query: query,
            variables: variables,
            hasErrors: hasErrors,
            errors: errors
        )
    }

    // MARK: - Operation Type Detection

    private static func detectOperationType(from query: String) -> GraphQLInfo.OperationType {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("mutation") { return .mutation }
        if trimmed.hasPrefix("subscription") { return .subscription }
        // "query" keyword or anonymous query (starts with { )
        return .query
    }

    // MARK: - Operation Name Extraction

    private static func extractOperationName(from query: String) -> String? {
        // Match patterns like:
        //   query GetUser { ... }
        //   mutation CreatePost($input: PostInput!) { ... }
        //   query GetUser($id: ID!) { ... }
        //   { user { ... } }  (anonymous — no name)
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)

        // Anonymous query starting with "{"
        if trimmed.hasPrefix("{") { return nil }

        // Pattern: (query|mutation|subscription)\s+(\w+)
        let pattern = #"^(?:query|mutation|subscription)\s+(\w+)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: trimmed, range: NSRange(trimmed.startIndex..., in: trimmed)),
              let nameRange = Range(match.range(at: 1), in: trimmed) else {
            return nil
        }

        return String(trimmed[nameRange])
    }

    // MARK: - Variables

    private static func formatVariables(_ variables: Any?) -> String? {
        guard let variables else { return nil }

        // Handle null
        if variables is NSNull { return nil }

        // Handle empty dict
        if let dict = variables as? [String: Any], dict.isEmpty { return nil }

        guard JSONSerialization.isValidJSONObject(variables),
              let data = try? JSONSerialization.data(withJSONObject: variables, options: [.prettyPrinted, .sortedKeys]),
              let string = String(data: data, encoding: .utf8) else {
            return nil
        }

        return string
    }

    // MARK: - Response Errors

    private static func parseResponseErrors(_ responseBody: String?) -> (hasErrors: Bool, errors: [GraphQLInfo.GraphQLError]) {
        guard let body = responseBody,
              let data = body.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let errorsArray = json["errors"] as? [[String: Any]] else {
            return (false, [])
        }

        let errors = errorsArray.compactMap { errorObj -> GraphQLInfo.GraphQLError? in
            guard let message = errorObj["message"] as? String else { return nil }
            let path = (errorObj["path"] as? [Any])?.map { String(describing: $0) }.joined(separator: ".")
            return GraphQLInfo.GraphQLError(message: message, path: path)
        }

        return (!errors.isEmpty, errors)
    }
}
