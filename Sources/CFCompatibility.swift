import CoreFoundation
import Foundation

/// CoreFoundation compatibility `HTTPMessage` alias
public typealias CFHTTPMessage = HTTPMessage

/// CoreFoundation compatibility `String` alias
//public typealias CFString = NSString

/// CoreFoundation compatibility `URL` alias
//public typealias CFURL = NSURL

/// Create a HTTP request message
///
/// - Parameters:
///   - allocator: must be `nil` or kCFAllocatorDefault
///   - method: HTTP method to use, e.g. `GET`
///   - url: URL for the request
///   - httpVersion: version of HTTP to use
/// - Returns: an HTTP request message
public func CFHTTPMessageCreateRequest(_ allocator: CFAllocator?, _ method: CFString, _ url: CFURL, _ httpVersion: CFString) -> CFHTTPMessage {
    let u = (url as NSURL).description
    return CFHTTPMessage(request: String(method), url: URL(string: u)!, httpVersion: String(httpVersion))
}

/// Create an empty HTTP request or response message
///
/// - Parameters:
///   - allocator: must be `nil` or kCFAllocatorDefault
///   - isRequest: Boolean indicating whether this should be a HTTP request
/// - Returns: an empty HTTP message
public func CFHTTPMessageCreateEmpty(_ allocator: CFAllocator?, _ isRequest: Bool) -> CFHTTPMessage {
    guard isRequest else { return CFHTTPMessage(response: 0) }
    return CFHTTPMessage(request: "", url: URL(fileURLWithPath: ""))
}

/// Return whether the given HTTP message is a request
///
/// - Parameter message: HTTP message to check
/// - Returns: `true` if this is a HTTP request
public func CFHTTPMessageIsRequest(_ message: CFHTTPMessage) -> Bool {
    return message.request != nil
}

/// Return whether the headers are complete for the given HTTP message
///
/// - Parameter message: HTTP message to check
/// - Returns: `true` if the headers are complete
public func CFHTTPMessageIsHeaderComplete(_ message: CFHTTPMessage) -> Bool {
    return message.headersComplete
}

/// Set the body data of a HTTP message
///
/// - Parameters:
///   - message: HTTP message to set the body data for
///   - body: message body data
public func CFHTTPMessageSetBody(_ message: CFHTTPMessage, _ body: CFData) {
    let d = body as NSData
    message.body = d as Data
}

/// Return the message body
///
/// - Parameter message: HTTP message to get the body data from
/// - Returns: message body data
public func CFHTTPMessageCopyBody(_ message: CFHTTPMessage) -> Unmanaged<CFData>? {
    guard var body = message.body else { return nil }
    return withUnsafePointer(to: &body) { Unmanaged.fromOpaque($0).retain() }
}

/// Return the message content (header+body) as serialised data
///
/// - Parameter message: the message to encode
/// - Returns: message content as data or `nil`
public func CFHTTPMessageCopySerializedMessage(_ message: CFHTTPMessage) -> Unmanaged<CFData>? {
    guard var content = message.messageData else { return nil }
    return withUnsafePointer(to: &content) { Unmanaged.fromOpaque($0).retain() }
}


/// Return the HTTP version used for the message
///
/// - Parameter message: the message to examine
/// - Returns: HTTP version used, e.g. `HTTP/1.1`
public func CFHTTPMessageCopyVersion(_ message: CFHTTPMessage) -> Unmanaged<CFString>? {
    var version = NSString(string: message.httpVersion)
    return withUnsafePointer(to: &version) { Unmanaged.fromOpaque($0).retain() }
}


/// Get the value for the given header field
///
/// - Parameter message: the message to examine
/// - Returns: HTTP version used, e.g. `HTTP/1.1`
public func CFHTTPMessageCopyHeaderFieldValue(_ message: CFHTTPMessage, _ header: CFString) -> Unmanaged<CFString>? {
    let key = (header as NSString).description
    guard let v = message.headers[key] else { return nil }
    var value = NSString(string: v)
    return withUnsafePointer(to: &value) { Unmanaged.fromOpaque($0).retain() }
}

/// Set the value of a given header key
///
/// - Parameters:
///   - message: the message to update
///   - header: header to set or clear
///   - value: content of the header or `nil`
public func CFHTTPMessageSetHeaderFieldValue(_ message: CFHTTPMessage, _ header: CFString, _ value: CFString?) {
    let key = (header as NSString).description
    let val = (value as? NSString)?.description
    message.set(header: key, value: val)
}

/// Return the HTTP version used for the message
///
/// - Parameter message: the message to examine
/// - Returns: all headers as a CFDictionary
public func CFHTTPMessageCopyAllHeaderFields(_ message: CFHTTPMessage) -> Unmanaged<CFDictionary>? {
    var headers = message.headers as NSDictionary
    return withUnsafePointer(to: &headers) { Unmanaged.fromOpaque($0).retain() }
}

/// Append bytes to the message body
///
/// - Parameters:
///   - message: the HTTP message to append to
///   - bytesToAppend: memory containing the bytest to append
///   - count: number of bytes to append
public func CFHTTPMessageAppendBytes(_ message: CFHTTPMessage, _ bytesToAppend: UnsafePointer<UInt8>, _ count: CFIndex) {
    let data = Data(bytes: UnsafeRawPointer(bytesToAppend), count: Int(count))
    if message.body == nil { message.body = data }
    else { message.body!.append(data) }
}
