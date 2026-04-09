import Foundation
@testable import Pry

/// Shared fixtures for Pry parser unit tests.
///
/// Kept intentionally small — only factories that are reused by more than
/// one test file live here. Single-use literals stay inline in their test
/// for readability.
enum TestFixtures {

    // MARK: - NetworkEntry Factory

    /// Builds a `NetworkEntry` with sensible defaults so each test only
    /// overrides the fields it cares about.
    static func makeEntry(
        timestamp: Date = Date(timeIntervalSince1970: 1_700_000_000),
        type: LogType = .network,
        requestURL: String = "https://api.example.com/v1/resource",
        requestMethod: String = "GET",
        requestHeaders: [String: String] = [:],
        requestBody: String? = nil,
        responseStatusCode: Int? = 200,
        responseHeaders: [String: String]? = ["Content-Type": "application/json"],
        responseBody: String? = nil,
        responseError: String? = nil,
        authToken: String? = nil,
        authTokenType: String? = nil,
        authTokenLength: Int? = nil,
        duration: TimeInterval? = 0.1,
        requestSize: Int? = nil,
        responseSize: Int? = nil,
        metrics: NetworkEntry.TimingMetrics? = nil
    ) -> NetworkEntry {
        NetworkEntry(
            timestamp: timestamp,
            type: type,
            requestURL: requestURL,
            requestMethod: requestMethod,
            requestHeaders: requestHeaders,
            requestBody: requestBody,
            responseStatusCode: responseStatusCode,
            responseHeaders: responseHeaders,
            responseBody: responseBody,
            responseError: responseError,
            authToken: authToken,
            authTokenType: authTokenType,
            authTokenLength: authTokenLength,
            duration: duration,
            requestSize: requestSize,
            responseSize: responseSize,
            metrics: metrics
        )
    }

    // MARK: - Protobuf Byte Helpers

    /// Encodes an unsigned 64-bit integer using the protobuf varint format.
    static func varint(_ value: UInt64) -> [UInt8] {
        var v = value
        var bytes: [UInt8] = []
        while v >= 0x80 {
            bytes.append(UInt8((v & 0x7F) | 0x80))
            v >>= 7
        }
        bytes.append(UInt8(v))
        return bytes
    }

    /// Builds a protobuf tag byte: `(fieldNumber << 3) | wireType`.
    static func tag(fieldNumber: Int, wireType: Int) -> [UInt8] {
        varint(UInt64((fieldNumber << 3) | wireType))
    }

    /// Encodes a field with wire type 0 (varint).
    static func varintField(fieldNumber: Int, value: UInt64) -> [UInt8] {
        tag(fieldNumber: fieldNumber, wireType: 0) + varint(value)
    }

    /// Encodes a field with wire type 2 (length-delimited) carrying a UTF-8 string.
    static func stringField(fieldNumber: Int, value: String) -> [UInt8] {
        let bytes = Array(value.utf8)
        return tag(fieldNumber: fieldNumber, wireType: 2)
            + varint(UInt64(bytes.count))
            + bytes
    }

    /// Encodes a field with wire type 2 (length-delimited) carrying raw bytes.
    static func bytesField(fieldNumber: Int, value: [UInt8]) -> [UInt8] {
        tag(fieldNumber: fieldNumber, wireType: 2)
            + varint(UInt64(value.count))
            + value
    }

    /// Encodes a field with wire type 5 (fixed32, little-endian).
    static func fixed32Field(fieldNumber: Int, value: UInt32) -> [UInt8] {
        var bytes = tag(fieldNumber: fieldNumber, wireType: 5)
        for i in 0..<4 {
            bytes.append(UInt8((value >> (8 * i)) & 0xFF))
        }
        return bytes
    }

    /// Encodes a field with wire type 1 (fixed64, little-endian).
    static func fixed64Field(fieldNumber: Int, value: UInt64) -> [UInt8] {
        var bytes = tag(fieldNumber: fieldNumber, wireType: 1)
        for i in 0..<8 {
            bytes.append(UInt8((value >> (8 * i)) & 0xFF))
        }
        return bytes
    }
}
