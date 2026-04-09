import Foundation
import Testing
@testable import Pry

@Suite("SessionExporter")
struct SessionExporterTests {

    // MARK: - cURL: single command

    @Test("Simple GET renders without --request flag")
    func simpleGetCurl() {
        let entry = TestFixtures.makeEntry(
            requestURL: "https://api.example.com/v1/users",
            requestMethod: "GET"
        )

        let curl = SessionExporter.curlCommand(for: entry)

        #expect(curl.hasPrefix("curl"))
        #expect(curl.contains("--location"))
        #expect(curl.contains("--silent"))
        #expect(curl.contains("--show-error"))
        // GET is the default — no --request flag needed.
        #expect(!curl.contains("--request"))
        #expect(curl.contains("'https://api.example.com/v1/users'"))
    }

    @Test("POST with JSON body includes --request and --data")
    func postJSONCurl() {
        let entry = TestFixtures.makeEntry(
            requestURL: "https://api.example.com/v1/users",
            requestMethod: "POST",
            requestHeaders: ["Content-Type": "application/json"],
            requestBody: #"{"name":"Alice"}"#
        )

        let curl = SessionExporter.curlCommand(for: entry)

        #expect(curl.contains("--request POST"))
        #expect(curl.contains("--header 'Content-Type: application/json'"))
        #expect(curl.contains(#"--data '{"name":"Alice"}'"#))
        #expect(curl.contains("'https://api.example.com/v1/users'"))
    }

    @Test("Body with single quotes is escaped")
    func curlEscapesSingleQuotes() {
        let entry = TestFixtures.makeEntry(
            requestMethod: "POST",
            requestBody: #"{"text":"it's broken"}"#
        )

        let curl = SessionExporter.curlCommand(for: entry)

        // escapeCurl replaces ' with '"'"'
        #expect(curl.contains("'\"'\"'"))
        // The original unescaped single quote should NOT appear as-is
        // surrounded by normal content — verify the escape was applied.
        #expect(!curl.contains("it's broken"))
    }

    @Test("Multiple headers are sorted and included")
    func curlSortsHeaders() {
        let entry = TestFixtures.makeEntry(
            requestMethod: "POST",
            requestHeaders: [
                "Authorization": "Bearer token123",
                "Content-Type": "application/json",
                "X-Custom": "value"
            ],
            requestBody: "{}"
        )

        let curl = SessionExporter.curlCommand(for: entry)

        #expect(curl.contains("--header 'Authorization: Bearer token123'"))
        #expect(curl.contains("--header 'Content-Type: application/json'"))
        #expect(curl.contains("--header 'X-Custom: value'"))

        // Sorted alphabetically — Authorization before Content-Type before X-Custom
        let authRange = curl.range(of: "Authorization")!
        let contentRange = curl.range(of: "Content-Type")!
        let customRange = curl.range(of: "X-Custom")!
        #expect(authRange.lowerBound < contentRange.lowerBound)
        #expect(contentRange.lowerBound < customRange.lowerBound)
    }

    @Test("Content-Length, Host, Accept-Encoding and User-Agent are stripped from cURL")
    func curlSkipsNoisyHeaders() {
        let entry = TestFixtures.makeEntry(
            requestMethod: "GET",
            requestHeaders: [
                "Content-Length": "42",
                "Host": "api.example.com",
                "Accept-Encoding": "gzip",
                "User-Agent": "PryTests/1.0",
                "X-Pry-Replay": "1",
                "X-Keep": "this"
            ]
        )

        let curl = SessionExporter.curlCommand(for: entry)

        #expect(!curl.contains("Content-Length"))
        #expect(!curl.contains("Host:"))
        #expect(!curl.contains("Accept-Encoding"))
        #expect(!curl.contains("User-Agent"))
        #expect(!curl.contains("X-Pry-Replay"))
        #expect(curl.contains("X-Keep"))
    }

    @Test("Image placeholder bodies are omitted from cURL")
    func curlOmitsImageBody() {
        let entry = TestFixtures.makeEntry(
            requestMethod: "POST",
            requestBody: "[IMAGE:1234:base64==]"
        )

        let curl = SessionExporter.curlCommand(for: entry)
        #expect(!curl.contains("--data"))
    }

    @Test("Binary data placeholders are omitted from cURL")
    func curlOmitsBinaryBody() {
        let entry = TestFixtures.makeEntry(
            requestMethod: "POST",
            requestBody: "[Binary data: 5000 bytes]"
        )

        let curl = SessionExporter.curlCommand(for: entry)
        #expect(!curl.contains("--data"))
    }

    // MARK: - cURL: collection

    @Test("cURL collection joins multiple entries with blank lines")
    func curlCollectionJoin() {
        let a = TestFixtures.makeEntry(requestURL: "https://a.example.com/one")
        let b = TestFixtures.makeEntry(requestURL: "https://b.example.com/two")

        let collection = SessionExporter.curlCollection(entries: [a, b])

        #expect(collection.contains("https://a.example.com/one"))
        #expect(collection.contains("https://b.example.com/two"))
        #expect(collection.contains("\n\n"))
    }

    @Test("cURL collection is empty for empty entries list")
    func curlCollectionEmpty() {
        let collection = SessionExporter.curlCollection(entries: [])
        #expect(collection.isEmpty)
    }

    // MARK: - Postman

    @Test("Postman collection contains info block and item array")
    func postmanBasicStructure() throws {
        let entry = TestFixtures.makeEntry(
            requestURL: "https://api.example.com/v1/users?limit=10",
            requestMethod: "GET"
        )

        let json = SessionExporter.postmanCollection(entries: [entry], name: "My Export")
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let root = try #require(parsed)

        let info = try #require(root["info"] as? [String: Any])
        #expect(info["name"] as? String == "My Export")
        let schema = info["schema"] as? String
        #expect(schema?.contains("collection/v2.1.0") == true)

        let items = try #require(root["item"] as? [[String: Any]])
        #expect(items.count == 1)

        let item = items[0]
        #expect((item["name"] as? String)?.contains("GET") == true)

        let request = try #require(item["request"] as? [String: Any])
        #expect(request["method"] as? String == "GET")

        let url = try #require(request["url"] as? [String: Any])
        #expect(url["raw"] as? String == "https://api.example.com/v1/users?limit=10")
        #expect(url["protocol"] as? String == "https")
        let host = try #require(url["host"] as? [String])
        #expect(host == ["api", "example", "com"])
        let path = try #require(url["path"] as? [String])
        #expect(path == ["v1", "users"])
        let query = try #require(url["query"] as? [[String: String]])
        #expect(query.first?["key"] == "limit")
        #expect(query.first?["value"] == "10")
    }

    @Test("Postman POST with JSON body uses raw mode")
    func postmanPostRawBody() throws {
        let entry = TestFixtures.makeEntry(
            requestMethod: "POST",
            requestHeaders: ["Content-Type": "application/json"],
            requestBody: #"{"name":"Alice"}"#
        )

        let json = SessionExporter.postmanCollection(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(parsed?["item"] as? [[String: Any]])
        let request = try #require(items.first?["request"] as? [String: Any])
        let body = try #require(request["body"] as? [String: Any])

        #expect(body["mode"] as? String == "raw")
        #expect(body["raw"] as? String == #"{"name":"Alice"}"#)
        let options = try #require(body["options"] as? [String: Any])
        let raw = try #require(options["raw"] as? [String: Any])
        #expect(raw["language"] as? String == "json")
    }

    @Test("Postman form-urlencoded body uses urlencoded mode")
    func postmanFormUrlencoded() throws {
        let entry = TestFixtures.makeEntry(
            requestMethod: "POST",
            requestHeaders: ["Content-Type": "application/x-www-form-urlencoded"],
            requestBody: "user=alice&role=admin&email=alice%40example.com"
        )

        let json = SessionExporter.postmanCollection(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(parsed?["item"] as? [[String: Any]])
        let request = try #require(items.first?["request"] as? [String: Any])
        let body = try #require(request["body"] as? [String: Any])

        #expect(body["mode"] as? String == "urlencoded")
        let encoded = try #require(body["urlencoded"] as? [[String: String]])
        #expect(encoded.count == 3)

        let userEntry = try #require(encoded.first { $0["key"] == "user" })
        #expect(userEntry["value"] == "alice")
        #expect(userEntry["type"] == "text")

        // Percent-decoded value
        let emailEntry = try #require(encoded.first { $0["key"] == "email" })
        #expect(emailEntry["value"] == "alice@example.com")
    }

    @Test("Postman headers exclude Content-Length and Host")
    func postmanHeadersFiltered() throws {
        let entry = TestFixtures.makeEntry(
            requestMethod: "GET",
            requestHeaders: [
                "Content-Length": "0",
                "Host": "api.example.com",
                "Authorization": "Bearer xyz",
                "X-Debug-Info": "debug"
            ]
        )

        let json = SessionExporter.postmanCollection(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(parsed?["item"] as? [[String: Any]])
        let request = try #require(items.first?["request"] as? [String: Any])
        let headers = try #require(request["header"] as? [[String: Any]])

        let keys = headers.compactMap { $0["key"] as? String }
        #expect(keys.contains("Authorization"))
        #expect(!keys.contains("Content-Length"))
        #expect(!keys.contains("Host"))
        #expect(!keys.contains("X-Debug-Info"))
    }

    @Test("Postman response is attached when status code is present")
    func postmanResponseAttached() throws {
        let entry = TestFixtures.makeEntry(
            responseStatusCode: 201,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: #"{"id":1}"#
        )

        let json = SessionExporter.postmanCollection(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(parsed?["item"] as? [[String: Any]])
        let responses = try #require(items.first?["response"] as? [[String: Any]])
        #expect(responses.count == 1)
        let response = responses[0]
        #expect(response["code"] as? Int == 201)
        #expect(response["status"] as? String == "Created")
        #expect(response["body"] as? String == #"{"id":1}"#)
    }

    @Test("Postman response is omitted when status code is nil (error entry)")
    func postmanNoResponseOnError() throws {
        let entry = TestFixtures.makeEntry(
            responseStatusCode: nil,
            responseHeaders: nil,
            responseBody: nil,
            responseError: "Network timed out",
            duration: nil
        )

        let json = SessionExporter.postmanCollection(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(parsed?["item"] as? [[String: Any]])
        let firstItem = try #require(items.first)
        // No "response" key means the exporter skipped it.
        #expect(firstItem["response"] == nil)
    }

    @Test("Postman collection handles empty entries list")
    func postmanEmptyList() throws {
        let json = SessionExporter.postmanCollection(entries: [])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let items = try #require(parsed?["item"] as? [[String: Any]])
        #expect(items.isEmpty)
    }

    // MARK: - HAR

    @Test("HAR archive has required log envelope")
    func harEnvelope() throws {
        let entry = TestFixtures.makeEntry(
            requestURL: "https://api.example.com/v1/items?page=2",
            requestMethod: "GET",
            requestHeaders: ["Authorization": "Bearer t"],
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: "{}"
        )

        let json = SessionExporter.harArchive(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let log = try #require(parsed?["log"] as? [String: Any])
        #expect(log["version"] as? String == "1.2")

        let creator = try #require(log["creator"] as? [String: Any])
        #expect(creator["name"] as? String == "Pry")
        #expect(creator["version"] as? String == "1.0")

        let entries = try #require(log["entries"] as? [[String: Any]])
        #expect(entries.count == 1)
    }

    @Test("HAR entry contains request, response and timings")
    func harEntryFields() throws {
        let metrics = NetworkEntry.TimingMetrics(
            dnsLookup: 0.01,
            tcpConnect: 0.02,
            tlsHandshake: 0.03,
            requestSent: 0.04,
            waitingForResponse: 0.05,
            responseReceived: 0.06,
            total: 0.21
        )
        let entry = TestFixtures.makeEntry(
            requestURL: "https://api.example.com/v1/items?page=2&limit=50",
            requestMethod: "POST",
            requestHeaders: ["Content-Type": "application/json"],
            requestBody: #"{"q":"swift"}"#,
            responseStatusCode: 200,
            responseHeaders: ["Content-Type": "application/json"],
            responseBody: #"{"ok":true}"#,
            requestSize: 13,
            responseSize: 11,
            metrics: metrics
        )

        let json = SessionExporter.harArchive(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let log = try #require(parsed?["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        let harEntry = entries[0]

        #expect(harEntry["startedDateTime"] != nil)
        // 0.1s * 1000 = 100ms — allow small float tolerance.
        let time = try #require(harEntry["time"] as? Double)
        #expect(abs(time - 100) < 0.001)

        // Request
        let request = try #require(harEntry["request"] as? [String: Any])
        #expect(request["method"] as? String == "POST")
        #expect(request["url"] as? String == "https://api.example.com/v1/items?page=2&limit=50")
        #expect(request["httpVersion"] as? String == "HTTP/1.1")
        let queryString = try #require(request["queryString"] as? [[String: String]])
        #expect(queryString.count == 2)
        let pageQS = try #require(queryString.first { $0["name"] == "page" })
        #expect(pageQS["value"] == "2")

        let postData = try #require(request["postData"] as? [String: Any])
        #expect(postData["mimeType"] as? String == "application/json")
        #expect(postData["text"] as? String == #"{"q":"swift"}"#)

        // Response
        let response = try #require(harEntry["response"] as? [String: Any])
        #expect(response["status"] as? Int == 200)
        #expect(response["statusText"] as? String == "OK")
        let content = try #require(response["content"] as? [String: Any])
        #expect(content["text"] as? String == #"{"ok":true}"#)

        // Timings — multiplications can introduce tiny float error.
        let timings = try #require(harEntry["timings"] as? [String: Any])
        let dns = try #require(timings["dns"] as? Double)
        let connect = try #require(timings["connect"] as? Double)
        let ssl = try #require(timings["ssl"] as? Double)
        #expect(abs(dns - 10) < 0.001)   // 0.01 * 1000
        #expect(abs(connect - 20) < 0.001) // 0.02 * 1000
        #expect(abs(ssl - 30) < 0.001)    // 0.03 * 1000
    }

    @Test("HAR error entry: status 0 is emitted when response missing")
    func harErrorEntry() throws {
        let entry = TestFixtures.makeEntry(
            responseStatusCode: nil,
            responseHeaders: nil,
            responseBody: nil,
            responseError: "NSURLErrorDomain -1009",
            duration: nil
        )

        let json = SessionExporter.harArchive(entries: [entry])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let log = try #require(parsed?["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        let harEntry = entries[0]
        let response = try #require(harEntry["response"] as? [String: Any])
        #expect(response["status"] as? Int == 0)
        #expect(response["statusText"] as? String == "")
    }

    @Test("HAR archive is valid JSON for empty entries list")
    func harEmpty() throws {
        let json = SessionExporter.harArchive(entries: [])
        let data = try #require(json.data(using: .utf8))
        let parsed = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let log = try #require(parsed?["log"] as? [String: Any])
        let entries = try #require(log["entries"] as? [[String: Any]])
        #expect(entries.isEmpty)
    }
}
