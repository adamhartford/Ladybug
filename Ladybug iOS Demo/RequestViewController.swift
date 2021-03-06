//
//  RequestViewController.swift
//  Ladybug
//
//  Created by Adam Hartford on 7/8/15.
//  Copyright (c) 2015 Adam Hartford. All rights reserved.
//

import UIKit
import Ladybug

class RequestViewController: UITableViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        Ladybug.baseURL = "https://httpbin.org"
        
        let certPath = NSBundle.mainBundle().URLForResource("httpbin.org", withExtension: "cer")!.absoluteString
        Ladybug.enableSSLPinning(.PublicKey, filePath: certPath, host: "httpbin.org")

        // Add header for all requests
        Ladybug.additionalHeaders["X-Foo"] = "Bar"

        // Callback for all requests
        Ladybug.willSend = { req in
            req.headers["X-WillSend"] = "Foo"
        }
        Ladybug.beforeSend = { req in
            req.setValue("Bar", forHTTPHeaderField:"X-BeforeSend")
        }
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        switch indexPath.row {
        case 0:
            sendGet()
        case 1:
            sendPost()
        case 2:
            sendPut()
        case 3:
            sendDelete()
        default:
            break
        }
    }
    
    func sendGet() {
        Ladybug.get("/get") { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetBasicAuth() {
        Ladybug.get("/basic-auth/user/passwd") { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetBasicAuthWithCredential() {
        let credential = NSURLCredential(user: "user", password: "passwd", persistence: .Permanent)
        Ladybug.get("/basic-auth/user/passwd", credential: credential) { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetEmoji() {
        🐞.get("/get") { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetWithParams() {
        let params = ["foo": "bar"]
        Ladybug.get("/get", parameters: params) { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetImage() {
        Ladybug.get("/image/png") { [weak self] response in
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendPost() {
        let params = ["foo": "bar"]
        Ladybug.post("/post", parameters: params) { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendPostMultipart() {
        let params = ["foo": "bar"]
        let files = [
            File(image: UIImage(named: "png")!, name: "mypng", fileName: "mypng", contentType: "image/png"),
            File(image: UIImage(named: "jpeg")!, name: "myjpeg", fileName: "myjpeg", contentType: "image/jpeg")
        ]
        
        Ladybug.post("/post", parameters: params, files: files) { [weak self] response in
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendPut() {
        let params = ["foo": "bar"]
        Ladybug.put("/put", parameters: params) { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendDelete() {
        let params = ["foo": "bar"]
        Ladybug.delete("/delete", parameters: params) { [weak self] response in
            print(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let response = sender as! Response
        let nav = segue.destinationViewController as! UINavigationController
        let controller = nav.topViewController as! ResponseViewController
        controller.response = response
        if segue.identifier == "showResponseImage" {
            controller.image = response.image
        }
    }

}