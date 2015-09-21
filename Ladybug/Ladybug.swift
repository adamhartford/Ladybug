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
    
    public static func enableSSLPinning(type: SSLPinningType, filePath: String, host: String) {
        sslPinning[host] = SSLPinningConfig(type: type, filePath: filePath)
    }
    
    public static func disableSSLPinning(host: String) {
        sslPinning.removeValueForKey(host)
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
            result += urlEncode(k) + "=" + urlEncode(v)
        }
        return result
    }
    
    public static func urlEncode(obj: AnyObject) -> String {
        return "\(obj)".stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())!
    }
}

class Client {
    static let sharedInstance = Client()
    private init() {}
    
    let session: NSURLSession = NSURLSession(configuration: NSURLSessionConfiguration.defaultSessionConfiguration(), delegate: LadybugDelegate(), delegateQueue: nil)
    
    func send(request: Request) {
        request.willSend?(request)
        Ladybug.willSend?(request)
        
        var urlString = request.url
        if request.method == .GET || request.method == .DELETE {
            urlString += Ladybug.queryString(request.parameters)
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
                let json = try? NSJSONSerialization.dataWithJSONObject(params, options: [])
                req.setValue("application/json", forHTTPHeaderField: Headers.ContentType)
                req.HTTPBody = json
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
                res = Response(status: httpResponse.statusCode, data: data, request: request, error: error)
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

public class Request: Equatable {
    let id: String!
    
    public var url: String
    public var method: HTTPMethod
    public var headers: [String: String]
    public var parameters: [String: AnyObject]?
    public var files: [File]?
    public var credential: NSURLCredential?
    public var willSend: (Request -> ())?
    public var beforeSend: (NSMutableURLRequest -> ())?
    public var done: (Response -> ())?
    
    public init(url: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        parameters: [String: AnyObject]? = nil,
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
            self.files = files
            self.credential = credential
            self.willSend = willSend
            self.beforeSend = beforeSend
            self.done = done
    }
}

public func == (lhs: Request, rhs: Request) -> Bool {
    return lhs.id == rhs.id
}

class LadybugDelegate: NSObject, NSURLSessionTaskDelegate {
    func URLSession(session: NSURLSession,
        task: NSURLSessionTask,
        didReceiveChallenge challenge: NSURLAuthenticationChallenge,
        completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential?) -> Void) {
            
            let id = NSURLProtocol.propertyForKey(Constants.LadybugURLProperty, inRequest: task.originalRequest!) as! String
            let req = Ladybug.pendingRequests[id]
            
            let serverTrust = challenge.protectionSpace.serverTrust!
            var allow: Bool?
            
            if challenge.previousFailureCount > 0 {
                completionHandler(.RejectProtectionSpace, nil)
                return
            }
            
            if let config = Ladybug.sslPinning[task.originalRequest!.URL!.host!] {
                let certificate = SecTrustGetCertificateAtIndex(serverTrust, 0)!
                let remoteCertData: NSData = SecCertificateCopyData(certificate)
                
                if let pinnedCertData = NSData(contentsOfFile: config.filePath) {
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
                completionHandler(.UseCredential, NSURLCredential(trust: serverTrust))
            } else if let proceed = allow {
                if proceed {
                    completionHandler(.UseCredential, NSURLCredential(trust: serverTrust))
                } else {
                    print("Invalid SSL certificate for host: \(task.originalRequest!.URL!.host!)")
                    #if os(iOS)
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                    #endif
                    // TODO cancel?
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
    
    init(status: Int = 0, data: NSData? = nil, request: Request, error: NSError? = nil) {
        self.status = status
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
}

#if os(iOS)
    public typealias Image = UIImage
#else
    public typealias Image = NSImage
#endif

public typealias 🐞 = Ladybug

