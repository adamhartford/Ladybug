//
//  Ladybug.swift
//  Ladybug
//
//  Created by Adam Hartford on 6/27/15.
//  Copyright (c) 2015 Adam Hartford. All rights reserved.
//

import Foundation
#if os(iOS)
    import UIKit
#else
    import AppKit
#endif

public struct Ladybug {
    public static var baseURL = ""
    public static var additionalHeaders: [String: String] = [:]
    public static var beforeSend: (Request -> ())?
    public static var done: (Response -> ())?
    public static var allowInvalidCertificates = false
    
    static var sslPinning: [String: SSLPinningConfig] = [:]
    
    public static func get(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .GET,
                headers: headers,
                parameters: parameters,
                done: done))
    }
    
    public static func post(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        files: [File]? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .POST,
                headers: headers,
                parameters: parameters,
                files: files,
                done: done))
    }
    
    public static func put(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .PUT,
                headers: headers,
                parameters: parameters,
                done: done))
    }
    
    public static func delete(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .DELETE,
                headers: headers,
                parameters: parameters,
                done: done))
    }
    
    public static func send(request: Request) {
        Client.sharedInstance.send(request)
    }
    
    public static func setBasicAuth(username: String, password: String) {
        let plainString = "\(username):\(password)" as NSString
        let plainData = plainString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = plainData?.base64EncodedStringWithOptions(.allZeros)
        additionalHeaders[Headers.Authorization] = "Basic \(base64String!)"
    }
    
    public static func enableSSLPinning(type: SSLPinningType, filePath: String, host: String) {
        sslPinning[host] = SSLPinningConfig(type: type, filePath: filePath)
    }
    
    public static func disableSSLPinning(host: String) {
        sslPinning.removeValueForKey(host)
    }
}

class Client {
    static let sharedInstance = Client()
    private init() {}
    
    let session: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: LadybugDelegate(), delegateQueue: nil)
    
    func send(request: Request) {
        var urlString = request.url
        if request.method == .GET || request.method == .DELETE {
            urlString += queryString(request.parameters)
        }
        
        let url = NSURL(string: urlString)!
        let req = NSMutableURLRequest(URL: url)
        req.HTTPMethod = request.method.rawValue
        
        for (header, value) in Ladybug.additionalHeaders {
            req.setValue(value, forHTTPHeaderField: header)
        }
        
        for (header, value) in request.headers {
            req.setValue(value, forHTTPHeaderField: header)
        }
        
        if request.method == .POST || request.method == .PUT {
            if let httpFiles = request.files {
                let body = NSMutableData()
                let boundary = "--\(Constants.MultipartBoundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
                
                if let params = request.parameters {
                    for (name, value) in params {
                        body.appendData(boundary)
                        body.appendData("Content-Disposition: form-data; name=\"\(name)\"\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                        body.appendData(value.dataUsingEncoding(NSUTF8StringEncoding)!)
                        body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                    }
                }
                
                for file in httpFiles {
                    body.appendData(boundary)
                    body.appendData("Content-Disposition: form-data; name=\"\(file.name)\"; filename=\"\(file.fileName)\"\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                    body.appendData("Content-Type: \(file.contentType)\r\n\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                    body.appendData(file.data)
                    body.appendData("\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                }
                
                if body.length > 0 {
                    body.appendData("--\(Constants.MultipartBoundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                }
                
                req.setValue("multipart/form-data; boundary=\(Constants.MultipartBoundary)", forHTTPHeaderField: Headers.ContentType)
                req.HTTPBody = body
            } else if let params = request.parameters {
                let json = NSJSONSerialization.dataWithJSONObject(params, options: .allZeros, error: nil)
                req.setValue("application/json", forHTTPHeaderField: Headers.ContentType)
                req.HTTPBody = json
            }
        }
        
        request.beforeSend?(request)
        Ladybug.beforeSend?(request)
        
        #if os(iOS)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        #endif
        
        let task = session.dataTaskWithRequest(req, completionHandler: { [weak self] (data, response, error) in
            #if os(iOS)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            #endif
            
            if let httpResponse = response as? NSHTTPURLResponse {
                let res = Response(status: httpResponse.statusCode, data: data, request: request)
                
                dispatch_async(dispatch_get_main_queue(), {
                    request.done?(res)
                    Ladybug.done?(res)
                })
            }
        })
        
        task.resume()
    }
    
    func queryString(parameters: [String: AnyObject]?) -> String {
        if let params = parameters {
            return "?" + urlEncode(params)
        }
        return ""
    }
    
    func urlEncode(obj: AnyObject) -> String {
        return "\(obj)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
    
    func urlEncode(parameters: [String: AnyObject]) -> String {
        var result = ""
        for (k,v) in parameters {
            if result != "" {
                result += "&"
            }
            result += urlEncode(k) + "=" + urlEncode(v)
        }
        return result
    }
}

public class Request {
    public var url: String
    public var method: HTTPMethod
    public var headers: [String: String]
    public var parameters: [String: AnyObject]?
    public var files: [File]?
    public var beforeSend: (Request -> ())?
    public var done: (Response -> ())?
    
    public init(url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        files: [File]? = nil,
        beforeSend: (Request -> ())? = nil,
        done: (Response -> ())? = nil) {
            
            self.url = url
            self.method = method
            self.headers = headers
            self.parameters = parameters
            self.files = files
            self.beforeSend = beforeSend
            self.done = done
    }
}

class LadybugDelegate: NSObject, NSURLSessionTaskDelegate {
    func URLSession(session: NSURLSession,
        task: NSURLSessionTask,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
            
            let serverTrust = challenge.protectionSpace.serverTrust
            var allow: Bool?
            
            if let config = Ladybug.sslPinning[task.originalRequest.URL!.host!] {
                let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0).takeRetainedValue()
                let remoteCertData: NSData = SecCertificateCopyData(certificate).takeRetainedValue()
                
                if let let pinnedCertData = NSData(contentsOfFile: config.filePath) {
                    switch config.type {
                    case .Certificate:
                        allow = remoteCertData.isEqualToData(pinnedCertData)
                    case .PublicKey:
                        let pinnedCert = SecCertificateCreateWithData(kCFAllocatorDefault, pinnedCertData).takeRetainedValue()
                        let pinnedPublicKey: AnyObject  = publicKey(pinnedCert) as! AnyObject
                        let remotePublicKey: AnyObject = publicKey(certificate) as! AnyObject
                        allow = pinnedPublicKey.isEqual(remotePublicKey)
                    default:
                        break
                    }
                }
            }
            
            if Ladybug.allowInvalidCertificates {
                completionHandler(.UseCredential, NSURLCredential(trust: serverTrust))
            } else if let proceed = allow {
                if proceed {
                    completionHandler(.UseCredential, NSURLCredential(trust: serverTrust))
                } else {
                    println("Invalid SSL certificate for host: \(task.originalRequest.URL!.host!)")
                    #if os(iOS)
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    #endif
                }
            } else {
                completionHandler(.PerformDefaultHandling, nil)
            }
    }
    
    func publicKey(cert: SecCertificate) -> SecKeyRef? {
        let policy = SecPolicyCreateBasicX509().takeRetainedValue()
        var expTrust: Unmanaged<SecTrust>?
        SecTrustCreateWithCertificates(cert, policy, &expTrust)
        if let trust = expTrust?.takeRetainedValue() {
            var result: SecTrustResultType = 0
            SecTrustEvaluate(trust, &result)
            return SecTrustCopyPublicKey(trust).takeRetainedValue()
        }
        return nil
    }
}

public class Response {
    public let status: Int
    public let data: NSData?
    public let request: Request
    
    public var text: String? {
        if let textData = data {
            return NSString(data: textData, encoding: NSUTF8StringEncoding) as? String
        }
        return nil
    }
    
    public var json: AnyObject? {
        if let jsonData = data {
            return NSJSONSerialization.JSONObjectWithData(jsonData, options: .allZeros, error: nil)
        }
        return nil
    }
    
    public var image: Image? {
        if let imageData = data {
            return Image(data: imageData)
        }
        return nil
    }
    
    init(status: Int, data: NSData?, request: Request) {
        self.status = status
        self.data = data
        self.request = request
    }
}

public struct File {
    public let data: NSData
    public let name: String
    public let fileName: String
    public let contentType: String
    
    public var image: Image? {
        return Image(data: data)
    }
    
    public init(image: Image, name: String, fileName: String, contentType: String = "application/octet-stream") {
        #if os(iOS)
            self.data = UIImagePNGRepresentation(image)
        #else
            let tiff = image.TIFFRepresentation
            self.data = NSBitmapImageRep(data: tiff!)!.representationUsingType(.NSPNGFileType, properties: [:])!
        #endif
        self.name = name
        self.fileName = fileName
        self.contentType = contentType
    }
    
    public init(data: NSData, name: String, fileName: String, contentType: String = "application/octet-stream") {
        self.data = data
        self.name = name
        self.fileName = fileName
        self.contentType = contentType
    }
}

struct Headers {
    static let ContentType = "Content-Type"
    static let Authorization = "Authorization"
}

struct Constants {
    static let MultipartBoundary = "LaDyBuGhTtPcLiEnT5239284"
    static let LadybugURLProperty = "LadybugURLProperty"
}

public enum SSLPinningType {
    case Certificate
    case PublicKey
}

struct SSLPinningConfig {
    let type: SSLPinningType
    let filePath: String
}

public enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
}

#if os(iOS)
    public typealias Image = UIImage
#else
    public typealias Image = NSImage
#endif

public typealias 🐞 = Ladybug

