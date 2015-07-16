//
//  ResponseViewController.swift
//  Ladybug
//
//  Created by Adam Hartford on 7/8/15.
//  Copyright (c) 2015 Adam Hartford. All rights reserved.
//

import UIKit
import Ladybug

class ResponseViewController: UIViewController {
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var textView: UITextView!
    
    var response: Response!

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = response.responseText
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func refresh(sender: AnyObject?) {
        textView.text = ""
        activityIndicator.startAnimating()
        
        let request = response.request
        request.done = { [weak self] res in
            println(res.data!)
            self?.textView.text = res.responseText
            self?.activityIndicator.stopAnimating()
        }
        Ladybug.send(request)
    }
    
    @IBAction func done(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
