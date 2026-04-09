import Foundation

/// Raw protobuf wire format decoder (no schema needed).
/// Extracts field numbers, wire types, and values from binary protobuf data.
enum ProtobufDecoder {

    /// Decodes raw protobuf binary data into a human-readable string.
    /// Returns nil if the data doesn't look like valid protobuf.
    static func decodeRaw(_ data: Data) -> String? {
        guard data.count >= 2 else { return nil }

        var reader = Reader(data: data)
        var fields: [DecodedField] = []
        var failCount = 0

        while reader.hasMore {
            guard let tag = reader.readVarint() else { break }
            let fieldNumber = Int(tag >> 3)
            let wireType = Int(tag & 0x07)

            // Sanity checks
            guard fieldNumber > 0 && fieldNumber < 10000 else { failCount += 1; break }
            guard wireType <= 5 else { failCount += 1; break }

            switch wireType {
            case 0: // Varint
                guard let value = reader.readVarint() else { failCount += 1; break }
                fields.append(DecodedField(number: fieldNumber, wireType: "varint", value: formatVarint(value)))

            case 1: // 64-bit fixed
                guard let value = reader.readFixed64() else { failCount += 1; break }
                fields.append(DecodedField(number: fieldNumber, wireType: "fixed64", value: "\(value)"))

            case 2: // Length-delimited (string, bytes, embedded message)
                guard let length = reader.readVarint(), length < 1_000_000,
                      let bytes = reader.readBytes(Int(length)) else { failCount += 1; break }
                let value = formatLengthDelimited(bytes)
                fields.append(DecodedField(number: fieldNumber, wireType: value.type, value: value.display))

            case 5: // 32-bit fixed
                guard let value = reader.readFixed32() else { failCount += 1; break }
                fields.append(DecodedField(number: fieldNumber, wireType: "fixed32", value: "\(value)"))

            default:
                failCount += 1
                break
            }

            if failCount > 2 { break }
        }

        // Need at least 1 valid field and low failure rate to consider it protobuf
        guard !fields.isEmpty, failCount <= 1 else { return nil }

        return formatOutput(fields, totalSize: data.count)
    }

    // MARK: - Formatting

    private static func formatVarint(_ value: UInt64) -> String {
        // Show boolean interpretation for 0/1
        if value == 0 { return "0 (false)" }
        if value == 1 { return "1 (true)" }
        // Show signed interpretation if negative zigzag
        let signed = Int64(bitPattern: (value >> 1) ^ (0 &- (value & 1)))
        if signed < 0 && signed > -1_000_000 {
            return "\(value) (signed: \(signed))"
        }
        return "\(value)"
    }

    private static func formatLengthDelimited(_ data: Data) -> (type: String, display: String) {
        // Try as UTF-8 string first
        if let string = String(data: data, encoding: .utf8),
           string.allSatisfy({ $0.isPrintable }) {
            let truncated = string.count > 120 ? String(string.prefix(120)) + "..." : string
            return ("string", "\"\(truncated)\"")
        }

        // Try as nested protobuf message
        if data.count >= 2, let nested = decodeRaw(data) {
            let indented = nested.split(separator: "\n").map { "  \($0)" }.joined(separator: "\n")
            return ("message", "{\n\(indented)\n}")
        }

        // Raw bytes
        if data.count <= 32 {
            let hex = data.map { String(format: "%02x", $0) }.joined(separator: " ")
            return ("bytes", "[\(data.count) bytes: \(hex)]")
        }
        return ("bytes", "[\(data.count) bytes]")
    }

    private static func formatOutput(_ fields: [DecodedField], totalSize: Int) -> String {
        var lines: [String] = []
        lines.append("Protobuf (\(totalSize) bytes, \(fields.count) fields)")
        lines.append("")

        for field in fields {
            lines.append("field \(field.number) (\(field.wireType)): \(field.value)")
        }

        return lines.joined(separator: "\n")
    }
}

// MARK: - Models

private struct DecodedField {
    let number: Int
    let wireType: String
    let value: String
}

// MARK: - Binary Reader

private struct Reader {
    let data: Data
    var offset: Int = 0

    var hasMore: Bool { offset < data.count }

    mutating func readVarint() -> UInt64? {
        var result: UInt64 = 0
        var shift: UInt64 = 0

        while offset < data.count {
            let byte = data[offset]
            offset += 1
            result |= UInt64(byte & 0x7F) << shift
            if byte & 0x80 == 0 { return result }
            shift += 7
            if shift > 63 { return nil }
        }
        return nil
    }

    mutating func readFixed32() -> UInt32? {
        guard offset + 4 <= data.count else { return nil }
        // Use loadUnaligned because protobuf fields can land on any byte offset,
        // and `load(as:)` traps on misaligned pointers on ARM64 (iPhone, iPad simulator).
        let value = data[offset..<offset+4].withUnsafeBytes { $0.loadUnaligned(as: UInt32.self) }
        offset += 4
        return value
    }

    mutating func readFixed64() -> UInt64? {
        guard offset + 8 <= data.count else { return nil }
        let value = data[offset..<offset+8].withUnsafeBytes { $0.loadUnaligned(as: UInt64.self) }
        offset += 8
        return value
    }

    mutating func readBytes(_ count: Int) -> Data? {
        guard count >= 0, offset + count <= data.count else { return nil }
        let result = data[offset..<offset+count]
        offset += count
        return Data(result)
    }
}

// MARK: - Character Extension

private extension Character {
    /// Whether this character is printable (letters, digits, punctuation, symbols,
    /// or common whitespace). Rejects C0/C1 control codes so binary payloads that
    /// happen to be valid UTF-8 aren't misclassified as strings.
    var isPrintable: Bool {
        unicodeScalars.allSatisfy { scalar in
            // Explicitly allow the whitespace we care about.
            if scalar == "\n" || scalar == "\r" || scalar == "\t" || scalar == " " {
                return true
            }
            switch scalar.properties.generalCategory {
            case .control,
                 .format,
                 .privateUse,
                 .surrogate,
                 .unassigned,
                 .lineSeparator,
                 .paragraphSeparator:
                return false
            default:
                return true
            }
        }
    }
}
