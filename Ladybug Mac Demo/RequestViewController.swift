//
//  ViewController.swift
//  Ladybug Mac Demo
//
//  Created by Adam Hartford on 6/17/15.
//  Copyright (c) 2015 Adam Hartford. All rights reserved.
//

import Cocoa
import Ladybug

class RequestViewController: NSViewController {
    @IBOutlet weak var progressIndicator: NSProgressIndicator!

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        Ladybug.baseURL = "http://httpbin.org"
        
        Ladybug.setBasicAuth("SomeUser", password: "SomePassword")
        
        // Add header for all requests
        Ladybug.additionalHeaders["X-Foo"] = "Bar"
        
        // Callback for all requests
        Ladybug.beforeSend = { [weak self] req in
            req.headers["X-Bar"] = "Baz"
            self?.progressIndicator.startAnimation(nil)
        }
        
        Ladybug.done = { [weak self] _ in
            self?.progressIndicator.stopAnimation(nil)
        }
    }

    @IBAction func sendGet(sender: AnyObject?) {
        Ladybug.get("/get") { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    @IBAction func sendGetWithParams(sender: AnyObject?) {
        let params = ["foo": "bar"]
        Ladybug.get("/get") { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    @IBAction func sendPost(sender: AnyObject?) {
        let params = ["foo": "bar"]
        Ladybug.post("/post", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    @IBAction func sendPut(sender: AnyObject?) {
        let params = ["foo": "bar"]
        Ladybug.put("/put", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    @IBAction func sendDelete(sender: AnyObject?) {
        let params = ["foo": "bar"]
        Ladybug.delete("/delete", parameters: params) { [weak self] response in
            println(response.json!)
            self?.performSegueWithIdentifier("showResponse", sender: response)
        }
    }
    
    // MARK: - Navigation
    
    override func prepareForSegue(segue: NSStoryboardSegue, sender: AnyObject?) {
        let controller = segue.destinationController as! ResponseViewController
        controller.response = sender as! Response
    }

}

