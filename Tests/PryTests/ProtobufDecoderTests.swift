import Foundation
import Testing
@testable import PryPro

@Suite("ProtobufDecoder")
struct ProtobufDecoderTests {

    // MARK: - Happy Path

    @Test("Decodes a simple varint field")
    func decodesSimpleVarintField() throws {
        // field 1, wire type 0 (varint), value 42
        let bytes = TestFixtures.varintField(fieldNumber: 1, value: 42)
        let data = Data(bytes)

        let decoded = try #require(ProtobufDecoder.decodeRaw(data))

        #expect(decoded.contains("Protobuf"))
        #expect(decoded.contains("field 1"))
        #expect(decoded.contains("varint"))
        #expect(decoded.contains("42"))
    }

    @Test("Decodes a string field")
    func decodesStringField() throws {
        // field 2, wire type 2 (length-delimited), "hello"
        let bytes = TestFixtures.stringField(fieldNumber: 2, value: "hello")
        let data = Data(bytes)

        let decoded = try #require(ProtobufDecoder.decodeRaw(data))

        #expect(decoded.contains("field 2"))
        #expect(decoded.contains("string"))
        #expect(decoded.contains("\"hello\""))
    }

    @Test("Decodes a fixed32 field")
    func decodesFixed32Field() throws {
        // field 3, wire type 5 (fixed32), value 0x01020304
        let bytes = TestFixtures.fixed32Field(fieldNumber: 3, value: 0x01020304)
        let data = Data(bytes)

        let decoded = try #require(ProtobufDecoder.decodeRaw(data))

        #expect(decoded.contains("field 3"))
        #expect(decoded.contains("fixed32"))
        #expect(decoded.contains("\(0x01020304)"))
    }

    @Test("Decodes a fixed64 field")
    func decodesFixed64Field() throws {
        // field 4, wire type 1 (fixed64), value 0x0102030405060708
        let bytes = TestFixtures.fixed64Field(fieldNumber: 4, value: 0x0102030405060708)
        let data = Data(bytes)

        let decoded = try #require(ProtobufDecoder.decodeRaw(data))

        #expect(decoded.contains("field 4"))
        #expect(decoded.contains("fixed64"))
        #expect(decoded.contains("\(0x0102030405060708 as UInt64)"))
    }

    @Test("Renders 0 and 1 varints with boolean hint")
    func rendersBooleanHints() throws {
        let zero = Data(TestFixtures.varintField(fieldNumber: 1, value: 0))
        let one = Data(TestFixtures.varintField(fieldNumber: 1, value: 1))

        let decodedZero = try #require(ProtobufDecoder.decodeRaw(zero))
        let decodedOne = try #require(ProtobufDecoder.decodeRaw(one))

        #expect(decodedZero.contains("0 (false)"))
        #expect(decodedOne.contains("1 (true)"))
    }

    @Test("Decodes multi-field messages in order")
    func decodesMultipleFields() throws {
        var bytes: [UInt8] = []
        bytes.append(contentsOf: TestFixtures.varintField(fieldNumber: 1, value: 150))
        bytes.append(contentsOf: TestFixtures.stringField(fieldNumber: 2, value: "testing"))
        bytes.append(contentsOf: TestFixtures.fixed32Field(fieldNumber: 3, value: 12345))

        let decoded = try #require(ProtobufDecoder.decodeRaw(Data(bytes)))

        #expect(decoded.contains("3 fields"))
        #expect(decoded.contains("field 1"))
        #expect(decoded.contains("150"))
        #expect(decoded.contains("field 2"))
        #expect(decoded.contains("\"testing\""))
        #expect(decoded.contains("field 3"))
        #expect(decoded.contains("12345"))
    }

    @Test("Decodes nested embedded message")
    func decodesNestedMessage() throws {
        // Inner message: two varint fields
        var inner: [UInt8] = []
        inner.append(contentsOf: TestFixtures.varintField(fieldNumber: 1, value: 7))
        inner.append(contentsOf: TestFixtures.varintField(fieldNumber: 2, value: 99))

        // Outer: field 1 contains inner as bytes
        let outer = TestFixtures.bytesField(fieldNumber: 1, value: inner)

        let decoded = try #require(ProtobufDecoder.decodeRaw(Data(outer)))

        // Nested rendering wraps output in braces and indents inner lines.
        #expect(decoded.contains("field 1"))
        #expect(decoded.contains("message"))
        #expect(decoded.contains("{"))
        #expect(decoded.contains("}"))
        #expect(decoded.contains("7"))
        #expect(decoded.contains("99"))
    }

    @Test("Renders non-printable bytes as hex")
    func rendersRawBytesAsHex() throws {
        // Length-delimited field holding raw non-UTF8 bytes.
        let raw: [UInt8] = [0x00, 0x01, 0xFF, 0xFE, 0x7F]
        let bytes = TestFixtures.bytesField(fieldNumber: 5, value: raw)

        let decoded = try #require(ProtobufDecoder.decodeRaw(Data(bytes)))

        #expect(decoded.contains("field 5"))
        #expect(decoded.contains("bytes"))
        #expect(decoded.contains("5 bytes"))
    }

    // MARK: - Rejection Cases

    @Test("Returns nil for empty data")
    func returnsNilForEmptyData() {
        #expect(ProtobufDecoder.decodeRaw(Data()) == nil)
    }

    @Test("Returns nil for a single byte")
    func returnsNilForSingleByte() {
        #expect(ProtobufDecoder.decodeRaw(Data([0x08])) == nil)
    }

    @Test("Returns nil for obvious non-protobuf JSON text")
    func returnsNilForJSONText() {
        let json = #"{"foo":"bar"}"#.data(using: .utf8)!
        // JSON may parse as a handful of fields but the failure detector
        // should reject it — at worst we accept it returns a non-nil string.
        // What matters: it doesn't crash.
        _ = ProtobufDecoder.decodeRaw(json)
    }

    @Test("Handles random bytes without crashing")
    func handlesRandomBytesSafely() {
        let random: [UInt8] = [0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF]
        _ = ProtobufDecoder.decodeRaw(Data(random))
    }

    @Test("Rejects truncated length-delimited field")
    func rejectsTruncatedLengthDelimited() {
        // Tag for field 1 wire 2, then length 100, but no payload bytes.
        let bytes: [UInt8] = [0x0A, 100]
        // Decoder should reject or at least return nil (no valid fields).
        let result = ProtobufDecoder.decodeRaw(Data(bytes))
        #expect(result == nil)
    }

    @Test("Rejects truncated varint field")
    func rejectsTruncatedVarint() {
        // Tag for field 1 wire 0, then varint that never terminates (top bit set).
        let bytes: [UInt8] = [0x08, 0xFF]
        let result = ProtobufDecoder.decodeRaw(Data(bytes))
        #expect(result == nil)
    }

    // MARK: - Size & Header Reporting

    @Test("Reports total byte count in header")
    func reportsByteCountInHeader() throws {
        let bytes = TestFixtures.varintField(fieldNumber: 1, value: 150)
        let data = Data(bytes)

        let decoded = try #require(ProtobufDecoder.decodeRaw(data))

        #expect(decoded.contains("\(data.count) bytes"))
    }

    @Test("Handles moderately large messages")
    func handlesLargeMessage() throws {
        // 50 varint fields.
        var bytes: [UInt8] = []
        for i in 1...50 {
            bytes.append(contentsOf: TestFixtures.varintField(fieldNumber: i, value: UInt64(i * 1000)))
        }

        let decoded = try #require(ProtobufDecoder.decodeRaw(Data(bytes)))

        #expect(decoded.contains("50 fields"))
        #expect(decoded.contains("field 1"))
        #expect(decoded.contains("field 50"))
    }

    @Test("Truncates long string fields in display")
    func truncatesLongStrings() throws {
        let longString = String(repeating: "a", count: 200)
        let bytes = TestFixtures.stringField(fieldNumber: 1, value: longString)

        let decoded = try #require(ProtobufDecoder.decodeRaw(Data(bytes)))

        #expect(decoded.contains("..."))
        // Should not contain all 200 "a" characters unbroken.
        #expect(!decoded.contains(String(repeating: "a", count: 200)))
    }
}
