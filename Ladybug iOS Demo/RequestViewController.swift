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
        
        Ladybug.baseURL = "http://httpbin.org"
        Ladybug.setBasicAuth("SomeUser", password: "SomePassword")

        // Add header for all requests
        Ladybug.additionalHeaders["X-Foo"] = "Bar"

        // Callback for all requests
        Ladybug.beforeSend = { req in
            req.headers["X-Bar"] = "Baz"
            println(req)
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
            sendGetImage()
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
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetWithParams() {
        let params = ["foo": "bar"]
        Ladybug.get("/get", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendGetImage() {
        Ladybug.get("/image/png", responseType: .Binary) { [weak self] response in
            //println(response.text!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendPost() {
        let params = ["foo": "bar"]
        Ladybug.post("/post", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendPostMultipart() {
        let params = ["foo": "bar"]
        let files = [
            File(name: "mypng", image: UIImage(named: "png")!, contentType: "image/png"),
            File(name: "myjpeg", image: UIImage(named: "jpeg")!, contentType: "image/jpeg")
        ]
        
        Ladybug.post("/post", parameters: params, files: files) { [weak self] response in
            //println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendPut() {
        let params = ["foo": "bar"]
        Ladybug.put("/put", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    func sendDelete() {
        let params = ["foo": "bar"]
        Ladybug.delete("/delete", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let response = sender as! Response
        let controller = segue.destinationViewController.topViewController as! ResponseViewController
        controller.response = response
        if segue.identifier == "showResponseImage" {
            controller.image = response.image
        }
    }

}