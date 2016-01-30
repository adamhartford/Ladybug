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
    public static var willSend: (Request -> ())?
    public static var beforeSend: (NSMutableURLRequest -> ())?
    public static var done: (Response -> ())?
    public static var allowInvalidCertificates = false
    public static var followRedirects = true
    public static var sendParametersAsJSON = true
    public static var multipartFormBoundary = Constants.MultipartBoundary
    
    public static var timeout: NSTimeInterval {
        set {
            let config = NSURLSessionConfiguration.defaultSessionConfiguration()
            config.timeoutIntervalForRequest = newValue
            config.timeoutIntervalForResource = newValue
            Client.sharedInstance.config = config
        }
        get {
            return Client.sharedInstance.config.timeoutIntervalForRequest
        }
    }
    
    static var sslPinning: [String: SSLPinningConfig] = [:]
    static var pendingRequests = [String: Request]()
    
    public static func get(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        credential: NSURLCredential? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .GET,
                headers: headers,
                parameters: parameters,
                credential: credential,
                done: done))
    }
    
    public static func post(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        files: [File]? = nil,
        credential: NSURLCredential? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .POST,
                headers: headers,
                parameters: parameters,
                files: files,
                credential: credential,
                done: done))
    }
    
    public static func put(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        credential: NSURLCredential? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .PUT,
                headers: headers,
                parameters: parameters,
                credential: credential,
                done: done))
    }
    
    public static func delete(url: String,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        credential: NSURLCredential? = nil,
        done: (Response -> ())? = nil) {
            
            Client.sharedInstance.send(Request(url: baseURL + url,
                method: .DELETE,
                headers: headers,
                parameters: parameters,
                credential: credential,
                done: done))
    }
    
    public static func send(request: Request) {
        Client.sharedInstance.send(request)
    }
    public static func setBasicAuth(username: String, password: String) {
        let plainString = "\(username):\(password)" as NSString
        let plainData = plainString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = plainData?.base64EncodedStringWithOptions(NSDataBase64EncodingOptions.init(rawValue: 0))
        additionalHeaders[Headers.Authorization] = "Basic \(base64String!)"
    }
    
    public static func enableSSLPinning(type: SSLPinningType, filePath: String, host: String) {
        sslPinning[host] = SSLPinningConfig(type: type, filePath: filePath)
    }
    
    public static func disableSSLPinning(host: String? = nil) {
        if let h = host {
            sslPinning.removeValueForKey(h)
        } else {
            sslPinning.removeAll()
        }
    }
    
    public static func queryString(parameters: [String: AnyObject]?) -> String {
        if let params = parameters {
            return "?" + urlEncode(params)
        }
        return ""
    }
    
    public static func urlEncode(parameters: [String: AnyObject]) -> String {
        var result = ""
        for (k,v) in parameters {
            if result != "" {
                result += "&"
            }
            if let arr = v as? [String] {
                for i in arr {
                    result += urlEncode(k) + "=" + urlEncode(i) + "&"
                }
                result = result.substringToIndex(result.endIndex.advancedBy(-1))
            } else {
                result += urlEncode(k) + "=" + urlEncode(v)
            }
        }
        return result
    }
    
    public static func urlEncode(obj: AnyObject) -> String {
        return "\(obj)".stringByAddingPercentEncodingWithAllowedCharacters(.URLQueryAllowedCharacterSet())!
    }
}

class Client {
    var config = NSURLSessionConfiguration.defaultSessionConfiguration()
    let delegate = LadybugDelegate()
    
    static let sharedInstance = Client()
    private init() {}
    
    func send(request: Request) {
        let session = NSURLSession(configuration: config, delegate: delegate, delegateQueue: nil)
        
        request.willSend?(request)
        Ladybug.willSend?(request)
        
        var urlString = request.url
        if (request.method == .GET || request.method == .DELETE || request.method == .PATCH) && request.parameters?.count > 0 {
            var q = Ladybug.queryString(request.parameters)
            if urlString.containsString("?") {
                q = "&" + q.substringFromIndex(q.startIndex.advancedBy(1))
            }
            urlString += q
        }
        
        let url = NSURL(string: urlString)!
        let req = NSMutableURLRequest(URL: url)
        req.HTTPMethod = request.method.rawValue
        
        for (header, value) in Ladybug.additionalHeaders {
            request.headers[header] = value
        }
        
        for (header, value) in request.headers {
            req.setValue(value, forHTTPHeaderField: header)
        }
        
        if request.method == .POST || request.method == .PUT {
            if let httpFiles = request.files where httpFiles.count > 0 {
                let body = NSMutableData()
                let boundary = "--\(Ladybug.multipartFormBoundary)\r\n".dataUsingEncoding(NSUTF8StringEncoding)!
                
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
                    body.appendData("--\(Ladybug.multipartFormBoundary)--\r\n".dataUsingEncoding(NSUTF8StringEncoding)!)
                }
                
                req.setValue("multipart/form-data; boundary=\(Ladybug.multipartFormBoundary)", forHTTPHeaderField: Headers.ContentType)
                req.HTTPBody = body
            } else if let body = request.body {
                if req.allHTTPHeaderFields?[Headers.ContentType] == nil {
                    if Ladybug.sendParametersAsJSON {
                        req.setValue("application/json", forHTTPHeaderField: Headers.ContentType)
                    } else {
                        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: Headers.ContentType)
                    }
                }
                req.HTTPBody = body
            } else if let params = request.parameters {
                if Ladybug.sendParametersAsJSON {
                    let json = try? NSJSONSerialization.dataWithJSONObject(params, options: [])
                    if req.allHTTPHeaderFields?[Headers.ContentType] == nil {
                        req.setValue("application/json", forHTTPHeaderField: Headers.ContentType)
                    }
                    req.HTTPBody = json
                } else {
                    let p = Ladybug.urlEncode(params)
                    if req.allHTTPHeaderFields?[Headers.ContentType] == nil {
                        req.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: Headers.ContentType)
                    }
                    req.HTTPBody = p.dataUsingEncoding(NSUTF8StringEncoding)
                }
            }
        }
        
        Ladybug.pendingRequests[request.id] = request
        NSURLProtocol.setProperty(request.id, forKey: Constants.LadybugURLProperty, inRequest: req)
        
        #if os(iOS)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        #endif
        
        request.beforeSend?(req)
        Ladybug.beforeSend?(req)
        
        let task = session.dataTaskWithRequest(req, completionHandler: { (data, response, error) in
            #if os(iOS)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            #endif
            
            Ladybug.pendingRequests[request.id] = nil
            NSURLProtocol.removePropertyForKey(Constants.LadybugURLProperty, inRequest: req)
            
            let res: Response
            if let httpResponse = response as? NSHTTPURLResponse {
                let headers = httpResponse.allHeaderFields as! [String: String]
                res = Response(status: httpResponse.statusCode, headers: headers, data: data, request: request, error: error)
            } else {
                res = Response(request: request, error: error)
            }
            
            dispatch_async(dispatch_get_main_queue(), {
                request.done?(res)
                Ladybug.done?(res)
            })
        })
        
        task.resume()
    }
}

public class Request: Equatable, Hashable {
    let id: String!
    
    public var url: String
    public var method: HTTPMethod
    public var headers: [String: String]
    public var parameters: [String: AnyObject]?
    public var body: NSData?
    public var files: [File]?
    public var credential: NSURLCredential?
    public var willSend: (Request -> ())?
    public var beforeSend: (NSMutableURLRequest -> ())?
    public var done: (Response -> ())?
    
    public init(url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
        body: NSData? = nil,
        files: [File]? = nil,
        credential: NSURLCredential? = nil,
        willSend: (Request -> ())? = nil,
        beforeSend: (NSMutableURLRequest -> ())? = nil,
        done: (Response -> ())? = nil) {
            
            self.id = NSUUID().UUIDString
            self.url = url
            self.method = method
            self.headers = headers
            self.parameters = parameters
            self.body = body
            self.files = files
            self.credential = credential
            self.willSend = willSend
            self.beforeSend = beforeSend
            self.done = done
    }
    
    public var hashValue: Int {
        get {
            return id.hashValue
        }
    }
}

public func == (lhs: Request, rhs: Request) -> Bool {
    return lhs.id == rhs.id
}

class LadybugDelegate: NSObject, NSURLSessionTaskDelegate {
    
    func URLSession(session: NSURLSession, task: NSURLSessionTask,
        willPerformHTTPRedirection response: NSHTTPURLResponse,
        newRequest request: NSURLRequest,
        completionHandler: (NSURLRequest?) -> Void) {
            
            completionHandler(Ladybug.followRedirects ? request : nil)
    }
    
    func URLSession(session: NSURLSession,
        task: NSURLSessionTask,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
            
            let id = NSURLProtocol.propertyForKey(Constants.LadybugURLProperty, inRequest: task.originalRequest!) as! String
            let req = Ladybug.pendingRequests[id]
            
            let serverTrust = challenge.protectionSpace.serverTrust
            var allow: Bool?
            
            if challenge.previousFailureCount > 0 {
                completionHandler(.RejectProtectionSpace, nil)
                return
            }
            
            if let config = Ladybug.sslPinning[task.originalRequest!.URL!.host!] {
                let certificate = SecTrustGetCertificateAtIndex(serverTrust!, 0)!
                let remoteCertData: NSData = SecCertificateCopyData(certificate)
                
                if let pinnedCertData = NSData(contentsOfURL: NSURL(string: config.filePath)!) {
                    switch config.type {
                    case .Certificate:
                        allow = remoteCertData.isEqualToData(pinnedCertData)
                    case .PublicKey:
                        let pinnedCert = SecCertificateCreateWithData(kCFAllocatorDefault, pinnedCertData)!
                        let pinnedPublicKey: AnyObject  = publicKey(pinnedCert) as! AnyObject
                        let remotePublicKey: AnyObject = publicKey(certificate) as! AnyObject
                        allow = pinnedPublicKey.isEqual(remotePublicKey)
                    }
                }
            }
            
            if Ladybug.allowInvalidCertificates {
                completionHandler(.UseCredential, NSURLCredential(trust: serverTrust!))
            } else if let proceed = allow {
                if proceed {
                    completionHandler(.UseCredential, NSURLCredential(trust: serverTrust!))
                } else {
                    print("Invalid SSL certificate for host: \(task.originalRequest!.URL!.host!)")
                    #if os(iOS)
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    #endif
                    // TODO cancel?
                    
                    Ladybug.pendingRequests[req!.id] = nil
                    let res = Response(status: 0, headers: [:], data: nil, request: req!, error: nil)
                    dispatch_async(dispatch_get_main_queue(), {
                        req!.done?(res)
                        Ladybug.done?(res)
                    })
                }
            } else if let credential = req?.credential {
                completionHandler(.UseCredential, credential)
            } else {
                completionHandler(.PerformDefaultHandling, nil)
            }
    }
    
    func publicKey(cert: SecCertificate) -> SecKeyRef? {
        let policy = SecPolicyCreateBasicX509()
        var expTrust: SecTrust?
        SecTrustCreateWithCertificates(cert, policy, &expTrust)
        if let trust = expTrust {
            var result: SecTrustResultType = 0
            SecTrustEvaluate(trust, &result)
            return SecTrustCopyPublicKey(trust)
        }
        return nil
    }
    
}

public class Response {
    public let status: Int
    public let headers: [String: String]
    public let data: NSData?
    public let request: Request
    public let error: NSError?
    
    public var text: String? {
        if let textData = data {
            return NSString(data: textData, encoding: NSUTF8StringEncoding) as? String
        }
        return nil
    }
    
    public var json: AnyObject? {
        if let jsonData = data {
            return try? NSJSONSerialization.JSONObjectWithData(jsonData, options: [])
        }
        return nil
    }
    
    public var image: Image? {
        if let imageData = data {
            return Image(data: imageData)
        }
        return nil
    }
    
    init(status: Int = 0, headers: [String: String] = [:], data: NSData? = nil, request: Request, error: NSError? = nil) {
        self.status = status
        self.headers = headers
        self.data = data
        self.request = request
        self.error = error
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
            self.data = UIImagePNGRepresentation(image)!
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
    static let Authorization = "Authorization"
    static let ContentType = "Content-Type"
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
    case PATCH = "PATCH"
}

#if os(iOS)
    public typealias Image = UIImage
#else
    public typealias Image = NSImage
#endif

public typealias 🐞 = Ladybug

