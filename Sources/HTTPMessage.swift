import CoreFoundation
import Foundation

/// The default HTTP version to use
let defaultHTTPVersion = "HTTP/1.1"

/// Type representing a HTTP message
public class HTTPMessage {
    /// URL associated with this message
    public var url: URL?
    /// raw message content
    public var content: Data?
    /// HTTP request
    public var request: String?
    /// HTTP response
    public var response: String?
    /// Method used, such as "GET", "PUT", etc
    public var method: String?

    /// Create a HTTP request message using a given method
    ///
    /// - Parameters:
    ///   - method: The HTTP method to use, such as `PUT`, `GET`
    ///   - url: URL associated with the request
    ///   - httpVersion: HTTP version to use, e.g. "HTTP/1.1"
    public init(method: String, url: URL, httpVersion: String = defaultHTTPVersion) {
        self.method = method
        self.url = url
        request = "\(method) \(url.path) \(httpVersion)"
    }

    /// Create a HTTP response message
    ///
    /// - Parameters:
    ///   - code: response code, e.g. `200`
    ///   - status: status message or `nil` for default
    ///   - httpVersion: HTTP version to use, e.g. "HTTP/1.1"
    public init(response code: Int, status: String? = nil, httpVersion: String = defaultHTTPVersion) {
        let status = status ?? statusMessage(for: code)
        response = "\(httpVersion) \(code) \(status)"
    }
}


