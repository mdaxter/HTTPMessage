import Foundation

/// The default HTTP version to use
let defaultHTTPVersion = "HTTP/1.1"

/// Type representing a HTTP message
public class HTTPMessage {
    /// URL associated with this message
    public var url: URL?
    /// raw message content
    public var body: Data?
    /// HTTP request
    public var request: String?
    /// HTTP response
    public var response: String?
    /// Method used, such as "GET", "PUT", etc
    public var method: String?
    /// Version of HTTP used, e.g. `HTTP/1.1`
    public var httpVersion: String
    /// Header keys (substring before `:` in the header fields
    public var headerKeys: [String] = []
    /// Headers as key/value pairs
    public var headers: [String : String] = [:]
    /// Return whether the headers are complete
    public var headersComplete = false

    /// Header content as a string
    public var header: String {
        return headerKeys.reduce("") { $0 + "\($1): \(headers[$1]!)\r\n" }
    }

    /// Header content serialised as Data
    public var headerData: Data? { return header.data(using: .utf8) }

    /// Message header and body serialised as Data
    public var messageData: Data? {
        guard let body = body,
              let headerData = (header + "\r\n").data(using: .utf8) else { return nil }
        return headerData + body
    }

    /// Create a HTTP request message using a given method
    ///
    /// - Parameters:
    ///   - request: The HTTP request method to use, such as `PUT`, `GET`
    ///   - url: URL associated with the request
    ///   - httpVersion: HTTP version to use, e.g. "HTTP/1.1"
    public init(request: String, url: URL? = nil, httpVersion: String = defaultHTTPVersion) {
        self.method = request
        self.url = url
        self.httpVersion = httpVersion
        self.request = "\(request) \(url?.path ?? "/") \(httpVersion)"
    }

    /// Create a HTTP response message
    ///
    /// - Parameters:
    ///   - code: response code, e.g. `200`
    ///   - status: status message or `nil` for default
    ///   - httpVersion: HTTP version to use, e.g. "HTTP/1.1"
    public init(response code: Int, status: String? = nil, httpVersion: String = defaultHTTPVersion) {
        let status = status ?? statusMessage(for: code)
        self.httpVersion = httpVersion
        response = "\(httpVersion) \(code) \(status)"
    }

    /// Set the value of a given HTTP header
    ///
    /// - Parameters:
    ///   - header: identifier (key) of the given header field
    ///   - value: content of the header field
    public func set(header key: String, value: String? = nil) {
        guard let value = value else {
            headers[key] = nil
            if let i = headerKeys.index(of: key) { headerKeys.remove(at: i) }
            return
        }
        headers[key] = value
        if let i = headerKeys.index(of: key) { headerKeys[i] = key }
        else { headerKeys.append(key) }
    }
}
