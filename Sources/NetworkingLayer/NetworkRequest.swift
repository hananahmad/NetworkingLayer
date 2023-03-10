//
//  File.swift
//  
//
//  Created by Hanan Ahmed on 9/6/22.
//

import Foundation

public struct NetworkRequest {
    let url: String
    let headers: [String: String]?
    let body: Data?
    let requestTimeOut: Float?
    let httpMethod: SmilesHTTPMethod
    
    public init(url: String,
                headers: [String: String]? = nil,
                reqBody: Encodable? = nil,
                reqTimeout: Float? = nil,
                httpMethod: SmilesHTTPMethod
    ) {
        self.url = url
        self.headers = headers
        self.body = reqBody?.encode()
        self.requestTimeOut = reqTimeout
        self.httpMethod = httpMethod
    }
    
    public init(url: String,
                headers: [String: String]? = nil,
                reqBody: Data? = nil,
                reqTimeout: Float? = nil,
                httpMethod: SmilesHTTPMethod
    ) {
        self.url = url
        self.headers = headers
        self.body = reqBody
        self.requestTimeOut = reqTimeout
        self.httpMethod = httpMethod
    }
    
    func buildURLRequest(with url: URL) -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = httpMethod.rawValue
        urlRequest.allHTTPHeaderFields = headers ?? [:]
        urlRequest.httpBody = body
        printRequestData()
        return urlRequest
    }
    
    private func printRequestData() {
        
        debugPrint("---------- Request URL ----------\n", url)
        debugPrint("---------- Request Method ----------\n", httpMethod.rawValue)
        if let headers = headers {
            debugPrint("---------- Request Headers ----------\n", headers)
        }
        if let body = body, let jsonString = body.prettyPrintedJSONString {
            debugPrint("---------- Request Body ----------\n", jsonString)
        }
        
    }
    
}

public enum SmilesHTTPMethod: String {
    case GET
    case POST
    case PUT
    case DELETE
}

public enum NetworkError: LocalizedError, Equatable {
    case badURL(_ error: String)
    case apiError(code: Int, error: String)
    case invalidJSON(_ error: String)
    case unauthorized(code: Int, error: String)
    case badRequest(code: Int, error: String)
    case serverError(code: Int, error: String)
    case noResponse(_ error: String)
    case unableToParseData(_ error: String)
    case unknown(code: Int, error: String)
    case networkNotReachable(_ error: String)
}

extension Encodable {
    func encode() -> Data? {
        do {
            return try JSONEncoder().encode(self)
        } catch {
            return nil
        }
    }
}

extension Data {
    
    var prettyPrintedJSONString: String? {
        guard let object = try? JSONSerialization.jsonObject(with: self),
              let data = try?JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }
        return prettyPrintedString as String
    }
    
}
