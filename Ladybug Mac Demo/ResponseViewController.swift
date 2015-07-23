//
//  ResponseViewController.swift
//  Ladybug
//
//  Created by Adam Hartford on 7/14/15.
//  Copyright (c) 2015 Adam Hartford. All rights reserved.
//

import Cocoa
import Ladybug

class ResponseViewController: NSViewController {
    
    @IBOutlet var textView: NSTextView!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    
    var response: Response!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.string = response.text
    }
    
    @IBAction func refresh(sender: AnyObject?) {
        textView.string = ""
        progressIndicator.startAnimation(nil)
        
        let request = response.request
        request.done = { [weak self] res in
            println(res.json!)
            self?.textView.string = res.text
            self?.progressIndicator.stopAnimation(nil)
        }
        Ladybug.send(request)
    }
    
}
