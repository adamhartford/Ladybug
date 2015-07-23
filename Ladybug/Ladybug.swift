//
//  Ladybug.swift
//  Ladybug
//
//  Created by Adam Hartford on 6/27/15.
//  Copyright (c) 2015 Adam Hartford. All rights reserved.
//

import Foundation
import WebKit

public struct Ladybug {
    public static var initURL: String {
        get {
            return Client.sharedInstance.initURL
        } set {
            Client.loadRemote = newValue != ""
            Client.sharedInstance.initURL = stringWithoutTrailingSlash(newValue)
        }
    }
    
    public static var baseURL: String {
        get {
            return Client.sharedInstance.baseURL
        } set {
            Client.loadRemote = newValue == ""
            Client.sharedInstance.baseURL = stringWithoutTrailingSlash(newValue)
        }
    }
    
    public static var timeout: Int {
        get {
            return Client.sharedInstance.timeout / 1000
        } set {
            Client.sharedInstance.timeout = newValue * 1000
        }
    }
    
    public static var cache: Bool {
        get {
            return Client.sharedInstance.cache
        } set {
            Client.sharedInstance.cache = newValue
        }
    }
    
    public static var beforeSend: (Request -> ())? {
        get {
            return Client.sharedInstance.beforeSend
        } set {
            Client.sharedInstance.beforeSend = newValue
        }
    }
    
    public static var done: (Response -> ())? {
        get {
            return Client.sharedInstance.done
        } set {
            Client.sharedInstance.done = newValue
        }
    }
    
    public static var fail: (Response -> ())? {
        get {
            return Client.sharedInstance.fail
        } set {
            Client.sharedInstance.fail = newValue
        }
    }
    
    public static func setBasicAuth(username: String, password: String) {
        let plainString = "\(username):\(password)" as NSString
        let plainData = plainString.dataUsingEncoding(NSUTF8StringEncoding)
        let base64String = plainData?.base64EncodedStringWithOptions(.allZeros)
        Client.sharedInstance.additionalHeaders["Authorization"] = "Basic \(base64String!)"
    }
    
    public static var additionalHeaders: [String: String] {
        get {
            return Client.sharedInstance.additionalHeaders
        } set {
            Client.sharedInstance.additionalHeaders = newValue
        }
    }
    
    public static func get(url: String, parameters: [String: AnyObject]? = nil, headers: [String: String] = [:], responseType: ResponseType = .Text, beforeSend: (Request -> ())? = nil, done: (Response -> ())? = nil) {
        send(stringWithLeadingSlash(url), method: .GET, parameters: parameters, headers: headers, responseType: responseType, beforeSend: beforeSend, done: done)
    }
    
    public static func post(url: String, parameters: [String: AnyObject]? = nil, files: [File]? = nil, headers: [String: String] = [:], responseType: ResponseType = .Text, beforeSend: (Request -> ())? = nil, done: (Response -> ())? = nil) {
        send(stringWithLeadingSlash(url), method: .POST, parameters: parameters, files: files, headers: headers, responseType: responseType, beforeSend: beforeSend, done: done)
    }
    
    public static func put(url: String, parameters: [String: AnyObject]? = nil, headers: [String: String] = [:], responseType: ResponseType = .Text, beforeSend: (Request -> ())? = nil, done: (Response -> ())? = nil) {
        send(stringWithLeadingSlash(url), method: .PUT, parameters: parameters, headers: headers, responseType: responseType, beforeSend: beforeSend, done: done)
    }
    
    public static func delete(url: String, parameters: [String: AnyObject]? = nil, headers: [String: String] = [:], responseType: ResponseType = .Text, beforeSend: (Request -> ())? = nil, done: (Response -> ())? = nil) {
        send(stringWithLeadingSlash(url), method: .DELETE, parameters: parameters, headers: headers, responseType: responseType, beforeSend: beforeSend, done: done)
    }
    
    public static func send(url: String, method: HttpMethod, parameters: [String: AnyObject]? = nil, files: [File]? = nil, headers: [String: String] = [:], responseType: ResponseType = .Text, beforeSend: (Request -> ())? = nil, done: (Response -> ())? = nil) {
        Client.sharedInstance.send(Request(method: method, url: baseURL + stringWithLeadingSlash(url), parameters: parameters, files: files, headers: headers, responseType: responseType, beforeSend: beforeSend, done: done))
    }
    
    public static func send(request: Request) {
        Client.sharedInstance.send(request)
    }
    
    private static func stringWithoutTrailingSlash(str: NSString) -> String {
        if str.hasSuffix("/") {
            return str.substringToIndex(str.length - 1)
        }
        return str as String
    }
    
    private static func stringWithLeadingSlash(str: NSString) -> String {
        if !str.hasPrefix("/") {
            return "/\(str)"
        }
        return str as String
    }
}

class Client: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
    static var loadRemote = false
    
    var webView: WKWebView!
    var ready = false
    var baseURL = ""
    var additionalHeaders = [String: String]()
    var pendingRequests = [String: Request]()
    var processingRequests = [String: Request]()
    var beforeSend: (Request -> ())? = nil
    var done: (Response -> ())? = nil
    var fail: (Response -> ())? = nil
    
    var initURL: String! {
        didSet {
            webView.loadRequest(NSURLRequest(URL: NSURL(string: initURL)!))
        }
    }
    
    var timeout = 0 {
        didSet {
            if ready {
                webView.evaluateJavaScript("ladybug.timeout = \(timeout)", completionHandler: nil)
            }
        }
    }
    
    var cache = false
    
    class var sharedInstance: Client {
        struct Static {
            static let instance: Client = Client()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        
        let config = WKWebViewConfiguration()
        config.userContentController.addScriptMessageHandler(self, name: "interOp")
        webView = WKWebView(frame: CGRectZero, configuration: config)
        webView.navigationDelegate = self
        
        if Client.loadRemote {
            return
        }
        
        #if COCOAPODS
            let bundle = NSBundle(identifier: "org.cocoapods.Ladybug")!
        #elseif LADYBUG_FRAMEWORK
            let bundle = NSBundle(identifier: "com.adamhartford.Ladybug")!
        #else
            let bundle = NSBundle.mainBundle()
        #endif
        
        let jsURL = bundle.URLForResource("Ladybug", withExtension: "js")!
        
        // Loading file:// URLs from NSTemporaryDirectory() works on iOS, not OS X.
        // Workaround on OS X is to include the script directly.
        
        #if os(iOS)
            let temp = NSURL(fileURLWithPath: NSTemporaryDirectory())!
            let jsTempURL = temp.URLByAppendingPathComponent("Ladybug.js")
            
            let fileManager = NSFileManager.defaultManager()
            fileManager.removeItemAtURL(jsTempURL, error: nil)
            
            fileManager.copyItemAtURL(jsURL, toURL: jsTempURL, error: nil)
            let jsInclude = "<script src='\(jsTempURL.absoluteString!)'></script>"
        #else
            let jsString = NSString(contentsOfURL: jsURL, encoding: NSUTF8StringEncoding, error: nil)!
            let jsInclude = "<script>\(jsString)</script>"
        #endif
        
        let html = "<!doctype html><html><head></head><body>\(jsInclude))</body></html>"
        webView.loadHTMLString(html, baseURL: bundle.bundleURL)
    }
    
    deinit {
        if let view = webView {
            webView.removeFromSuperview()
        }
    }
    
    func send(request: Request) {
        if !ready {
            pendingRequests[request.id] = request
            return
        }
        
        for (k,v) in additionalHeaders {
            request.headers[k] = v
        }
        
        // Cache
        if !Ladybug.cache && request.method == .GET {
            let ms = Int64(NSDate().timeIntervalSince1970 * 1000)
            if request.parameters != nil {
                request.parameters!["_"] = "\(ms)"
            } else {
                request.parameters = ["_": "\(ms)"]
            }
        }
        
        request.beforeSend?(request)
        beforeSend?(request)
        
        // Params
        var data = "null"
        if let p: AnyObject = request.parameters {
            data = jsonStringFromObject(p)!
        }
        
        var filesJSON = "null"
        if let files = request.files {
            var arr = [AnyObject]()
            for file in files {
                arr.append(file.json)
            }
            filesJSON = jsonStringFromObject(arr)!
            println(filesJSON)
        }
        
        var headers = jsonStringFromObject(request.headers)!
        
        let id = NSUUID().UUIDString
        processingRequests[request.id] = request
        #if os(iOS)
            UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        #endif
        webView.evaluateJavaScript("send('\(request.id)', '\(request.method.stringValue)', '\(request.url)', \(data), \(filesJSON), \(headers), '\(request.responseType.stringValue)')", completionHandler: nil)
    }
    
    func jsonStringFromObject(obj: AnyObject?) -> String? {
        if let o: AnyObject = obj {
            if let data = NSJSONSerialization.dataWithJSONObject(o, options: NSJSONWritingOptions.allZeros, error: nil) {
                return NSString(data: data, encoding: NSUTF8StringEncoding) as? String
            }
            return nil
        }
        return nil
    }
    
    func jsonObjectFromString(str: String) -> AnyObject? {
        if let data = str.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false) {
            return NSJSONSerialization.JSONObjectWithData(data, options: .allZeros, error: nil)!
        }
        return nil
    }
    
    // MARK: - WKNavigationDelegate
    
    func webView(webView: WKWebView, didFinishNavigation navigation: WKNavigation!) {
        #if os(iOS)
            UIApplication.sharedApplication().keyWindow?.addSubview(webView)
        #endif
    }
    
    func webView(webView: WKWebView, didReceiveAuthenticationChallenge challenge: NSURLAuthenticationChallenge, completionHandler: (NSURLSessionAuthChallengeDisposition, NSURLCredential!) -> Void) {
        // TODO support SSL pinning (cert, public key, etc.)
        // TODO Allow invalid certs if desired?
    }
    
    // MARK: - WKScriptMessageHandler
    
    func userContentController(userContentController: WKUserContentController, didReceiveScriptMessage message: WKScriptMessage) {
        let json = message.body as! [String: AnyObject]
        //let json: AnyObject = jsonObjectFromString(message.body as! String)!
        let msg = json["message"] as! String
        
        switch msg {
        case "ready":
            ready = true
            Ladybug.timeout = timeout
            Ladybug.cache = cache
            
            for (_, request) in pendingRequests {
                send(request)
            }
            pendingRequests.removeAll(keepCapacity: false)
        case "response":
            let request = processingRequests[json["id"] as! String]!
            let res: AnyObject = json["response"] as AnyObject!
            let status = res["status"] as! Int
            let success = status >= 200 && status < 300
            
            let response = Response(request: request,
                success: success,
                error: !success,
                status: status,
                statusText: res["statusText"] as! String,
                responseText: res["responseText"] as? String,
                base64: res["base64"] as? String)
            
            #if os(iOS)
                UIApplication.sharedApplication().networkActivityIndicatorVisible = false
            #endif
            
            // Global handlers
            if response.success {
                done?(response)
            } else {
                fail?(response)
            }
            
            // Local handler
            processingRequests.removeValueForKey(request.id)
            request.done?(response)
        default:
            break
        }
    }
}

public enum HttpMethod {
    case GET
    case POST
    case PUT
    case DELETE
    
    var stringValue: String {
        switch self {
        case .POST:
            return "POST"
        case .PUT:
            return "PUT"
        case .DELETE:
            return "DELETE"
        default:
            return "GET"
        }
    }
}

public enum ResponseType {
    case Text
    case Binary
    
    var stringValue: String {
        switch self {
        case .Binary:
            return "blob"
        default:
            return "text"
        }
    }
}

public struct File {
    public let name: String
    public let contentType: String
    public let data: NSData?
    public let image: Image?
    
    public init(name: String, image: Image, contentType: String = "application/octet-stream") {
        self.name = name
        self.image = image
        self.data = nil
        self.contentType = contentType
    }
    
    public init(name: String, data: NSData, contentType: String = "application/octet-stream") {
        self.name = name
        self.data = data
        self.image = nil
        self.contentType = contentType
    }
    
    public var json: [String: String] {
        var result = ["name": name, "contentType": contentType]
        if let d = data {
            result["data"] = d.base64EncodedStringWithOptions(.allZeros)
        } else if let img = image {
            #if os(iOS)
                result["data"] = UIImagePNGRepresentation(image).base64EncodedStringWithOptions(.allZeros)
            #else
                let tiff = img.TIFFRepresentation
                let png = NSBitmapImageRep(data: tiff!)!.representationUsingType(.NSPNGFileType, properties: [:])!
                result["data"] = png.base64EncodedStringWithOptions(.allZeros)
            #endif
        }
        return result
    }
}

public class Request: Printable {
    var id: String
    public var method: HttpMethod
    public var url: String
    public var parameters: [String: AnyObject]?
    public var files: [File]?
    public var headers: [String: String]
    public var responseType: ResponseType
    public var beforeSend: (Request -> ())?
    public var done: (Response -> ())?
    
    public var description: String {
        get {
            var components = NSURLComponents(string: url)!
            var queryItems = [NSURLQueryItem]()
            
            if let params = parameters as? Dictionary<String, String> {
                for (k,v) in params {
                    queryItems.append(NSURLQueryItem(name: k, value: v))
                }
                components.queryItems = queryItems
            }
            
            var result = "\(method.stringValue.uppercaseString) \(components.path!)"
            
            if method == .GET || method == .DELETE {
                if queryItems.count > 0 {
                    result += "?" + components.query!
                }
            }
            
            let sortedArray = sorted(headers, { $0.0 < $1.0 })
            let keys = sortedArray.map { return $0.0 }
            
            for key in keys {
                result += "\n" + key + ": " + headers[key]!
            }
            
            if method == .POST || method == .PUT {
                if let params: AnyObject = parameters {
                    if let data = NSJSONSerialization.dataWithJSONObject(params, options: .allZeros, error: nil) {
                        let json = NSString(data: data, encoding: NSUTF8StringEncoding) as! String
                        result += "\n\n" + json
                    }
                }
                
            }
            
            return result
        }
    }
    
    init(method: HttpMethod = .GET, url: String = "/", parameters: [String: AnyObject]?, files: [File]?, headers: [String: String] = [:], responseType: ResponseType = .Text, beforeSend: (Request -> ())?, done: (Response -> ())?) {
        id = NSUUID().UUIDString
        self.method = method
        self.url = url
        self.parameters = parameters
        self.files = files
        self.headers = headers
        self.responseType = responseType
        self.beforeSend = beforeSend
        self.done = done
    }
}

public class Response {
    public let request: Request
    public let success: Bool
    public let error: Bool
    public let status: Int
    public let statusText: String
    let responseText: String?
    let base64: String?
    
    public var data: NSData? {
        if let text = responseText {
            return text.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
        } else if let b64 = base64 {
            return NSData(base64EncodedString: b64, options: .allZeros)
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
    
    public var text: String? {
        if let text = responseText {
            return text
        } else if let text = base64 {
            return text
        }
        return nil
    }
    
    init (request: Request, success: Bool, error: Bool, status: Int, statusText: String, responseText: String?, base64: String?) {
        self.request = request
        self.success = success
        self.error = error
        self.status = status
        self.statusText = statusText
        self.responseText = responseText
        self.base64 = base64
    }
}

#if os(iOS)
    public typealias Image = UIImage
    #else
    public typealias Image = NSImage
#endif
