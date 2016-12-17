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
    /// Response code (non-nil if a response)
    public var responseCode: Int?
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

    /// Return true if this is a response
    public var isResponse: Bool { return responseCode != nil }

    /// Return true if this is a request
    public var isRequest: Bool { return responseCode == nil }

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
    public convenience init(request: String, url: URL? = nil, httpVersion v: String = defaultHTTPVersion) {
        self.init(httpVersion: v)
        method = request
        self.url = url
        self.request = "\(request) \(url?.path ?? "/") \(v)"
    }

    /// Create a HTTP response message
    ///
    /// - Parameters:
    ///   - code: response code, e.g. `200`
    ///   - status: status message or `nil` for default
    ///   - httpVersion: HTTP version to use, e.g. "HTTP/1.1"
    public convenience init(response code: Int, status: String? = nil, httpVersion v: String = defaultHTTPVersion) {
        self.init(httpVersion: v)
        let status = status ?? statusMessage(for: code)
        response = "\(v) \(code) \(status)"
    }

    /// Create an empty HTTP message
    ///
    /// - Parameter httpVersion: HTTP version to use, e.g. "HTTP/1.1"
    public init(isResponse: Bool = false, httpVersion: String = defaultHTTPVersion) {
        self.httpVersion = httpVersion
        if isResponse { responseCode = 0 }
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

    /// Append data to the body
    ///
    /// - Parameter data: the data to append
    public func append(_ data: Data) {
        if body != nil { body!.append(data) }
        else { body = data }
        if !headersComplete {
            
        }
    }
}
