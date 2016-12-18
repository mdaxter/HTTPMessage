import Foundation

/// The default HTTP version to use
let defaultHTTPVersion = "HTTP/1.1"

/// Hunt for end of line
///
/// - Parameters:
///   - data: the data to check
///   - start: start index to check from
///   - end: end index to check from
/// - Returns: `nil` if not found, else `delimiterIndex` of the eol delimeter, `nextLineIndex` of the beginning of the next line, `crlf` whether there was a CR
func endOfLine(for data: Data, inRange range: Range<Data.Index>) -> (delimiterIndex: Data.Index, nextLineIndex: Data.Index, crlf: Bool)? {
    var eolIndex: Data.Index?
    let slice = data.subdata(in: range)
    let lfIndex = slice.index(of: 10)
    let crIndex = slice.index(of: 13)
    let hasCR: Bool
    if let cr = crIndex {
        eolIndex = cr
        hasCR = true
    } else {
        hasCR = false
        if let lf = lfIndex { eolIndex = lf }
    }
    guard let eol = eolIndex else { return nil }
    let nextLine: Data.Index
    let endOfLine: Data.Index
    if let cr = crIndex, let lf = lfIndex, abs(lf-cr) == 1 {
        endOfLine = min(cr, lf)
        nextLine = slice.index(after: max(cr, lf))
    } else {
        endOfLine = eol
        nextLine = slice.index(after: eol)
    }
    return (delimiterIndex: endOfLine, nextLineIndex: nextLine, crlf: hasCR)
}


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
    /// Return whether header lines are delimited by CR(+LF) rather than just LF
    public var delimitedByCR = true

    /// Return true if this is a response
    public var isResponse: Bool { return responseCode != nil }

    /// Return true if this is a request
    public var isRequest: Bool { return responseCode == nil }

    /// Header content as a string
    public var header: String? {
        guard let firstLine = response ?? request else { return nil }
        return headerKeys.reduce(firstLine + "\r\n") { $0 + "\($1): \(headers[$1]!)\r\n" }
    }

    /// Header content serialised as Data
    public var headerData: Data? { return header?.data(using: .utf8) }

    /// Message header and body serialised as Data
    public var messageData: Data? {
        guard let headerData = header?.data(using: .utf8) else { return nil }
        return body == nil ? headerData : (headerData + body!)
    }

    /// Header that needs completion
    var incompleteHeader: String?

    /// Parsed response status line
    func getResponseStatus() -> (complete: Bool, http: String?, code: Int?, line: String)? {
        let status: String
        var lineComplete = false
        if let responseLine = response {
            status = responseLine
            lineComplete = true
        } else {
            guard let header = body else { return nil }
            if let eol = endOfLine(for: header, inRange: header.startIndex..<header.endIndex) {
                let firstLineData = header.subdata(in: header.startIndex..<eol.delimiterIndex)
                response = String(data: firstLineData, encoding: .utf8)
                status = response ?? ""
                body = header.subdata(in: eol.nextLineIndex..<header.endIndex)
                lineComplete = true
                delimitedByCR = eol.crlf
            } else {
                guard let string = String(data: header, encoding: .utf8) else {
                    if header.isEmpty { return nil }
                    return (complete: true, http: nil, code: nil, line: "")
                }
                status = string
            }
        }
        let space = UTF16.CodeUnit(32)
        let u16 = status.utf16
        let utfields = u16.split(separator: space, omittingEmptySubsequences: true)
        if utfields.count < 3 {
            guard lineComplete else { return nil }
            return (complete: true, http: nil, code: nil, line: "")
        }
        let httpField = utfields[0]
        let httpVersion: String?
        var numericalCode: Int?
        if u16.count >= 8 {
            httpVersion = String(describing: httpField)
            if !httpVersion!.hasPrefix("HTTP/") { lineComplete = true }
            if utfields.count > 1 {
                numericalCode = Int(String(describing: utfields[1]))
                lineComplete = true
            }
        } else {
            httpVersion = nil
        }
        return (complete: lineComplete,
                http: httpVersion,
                code: numericalCode,
                line: status)
    }

    
    /// Parsed request status line
    func getFirstLineOfRequest() -> (complete: Bool, http: String?, request: String?, url: String?, line: String)? {
        let status: String
        var lineComplete = false
        if let requestLine = request {
            status = requestLine
            lineComplete = true
        } else {
            guard let header = body else { return nil }
            if let eol = endOfLine(for: header, inRange: header.startIndex..<header.endIndex) {
                let firstLineData = header.subdata(in: header.startIndex..<eol.delimiterIndex)
                request = String(data: firstLineData, encoding: .utf8)
                status = request ?? ""
                body = header.subdata(in: eol.nextLineIndex..<header.endIndex)
                lineComplete = true
                delimitedByCR = eol.crlf
            } else {
                guard let string = String(data: header, encoding: .utf8) else {
                    if header.isEmpty { return nil }
                    return (complete: true, http: nil, request: nil, url: nil, line: "")
                }
                status = string
            }
        }
        let space = UTF16.CodeUnit(32)
        let u16 = status.utf16
        let utfields = u16.split(separator: space, omittingEmptySubsequences: true)
        let n = utfields.count
        if n > 3 { lineComplete = true }
        if n > 3 || n < 2 {
            guard lineComplete else { return nil }
            return (complete: true, http: nil, request: nil, url: nil, line: "")
        }
        let requestField = String(describing: utfields[0])
        let urlField = String(describing: utfields[1])
        let httpVersion = utfields.count > 2 ? String(describing: utfields[2]) : "HTTP/1.0"
        if httpVersion.utf16.count >= 8 {
            if !httpVersion.hasPrefix("HTTP/") { lineComplete = true }
        }
        return (complete: lineComplete,
                http: httpVersion,
                request: requestField,
                url: urlField,
                line: status)
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
    /// - Returns: `true` if header parsing was successful
    public func append(_ data: Data) -> Bool {
        if body != nil { body!.append(data) }
        else { body = data }
        if headersComplete { return true }

        // need to check if complete and parse headers
        if isResponse {
            if response == nil {
                if let status = getResponseStatus() {
                    if let version = status.http {
                        httpVersion = version
                    }
                    if let code = status.code {
                        responseCode = code
                    }
                    response = status.line
                    if status.complete {
                        guard responseCode != nil && responseCode != 0 && response != nil else {
                            return false
                        }
                    } else {
                        return true // first line not complete yet
                    }
                }
            }
        } else {
            if request == nil {
                if let status = getFirstLineOfRequest() {
                    if let version = status.http {
                        httpVersion = version
                    }
                    if let requestMethod = status.request {
                        method = requestMethod
                    }
                    if let urlString = status.url,
                        let uri = URL(string: urlString) {
                        url = uri
                    }
                    if status.complete {
                        guard method != nil && url != nil && httpVersion.hasPrefix("HTTP/") else {
                            return false
                        }
                    } else {
                        return true // first line not complete yet
                    }
                }
            }
        }
        var beg = body!.startIndex
        let end = body!.endIndex
        while !headersComplete && beg != end {
            let start = beg
            guard let eol = endOfLine(for: body!, inRange: start..<end) else {
                return true
            }
            let line = body!.subdata(in: start..<eol.delimiterIndex)
            guard !line.isEmpty else {
                headersComplete = true
                beg = eol.nextLineIndex
                break
            }
            let s: Data.Index
            let e = line.endIndex
            let key: String
            if isspace(Int32(line.first!)) != 0 {
                guard let k = incompleteHeader else {
                    headersComplete = true
                    return false
                }
                key = k
                s = line.startIndex
            } else {
                guard let colon = line.index(of: UInt8(":".utf16.first!)),
                      let k = String(data: line.subdata(in: line.startIndex..<colon), encoding: .utf8) else {
                    headersComplete = true
                    return false
                }
                key = k
                headerKeys.append(key)
                s = colon
            }
            var j = e
            for i in line.index(after: s)..<e {
                guard isspace(Int32(line[i])) != 0 else {
                    j = i
                    break
                }
            }
            incompleteHeader = key
            let val: String
            if j == e {
                val = ""
            } else {
                guard let v = String(data: line.subdata(in: j..<e), encoding: .utf8) else {
                    headersComplete = true
                    return false
                }
                val = v
            }
            if let oldVal = headers[key], !oldVal.isEmpty {
                headers[key] = "\(oldVal), \(val)"
            } else {
                headers[key] = val
            }
            beg = eol.nextLineIndex
        }
        body = body!.subdata(in: beg..<end)
        return true
    }
}
