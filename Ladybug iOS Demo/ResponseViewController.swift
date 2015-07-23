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
    @IBOutlet weak var imageView: UIImageView!
    
    var response: Response!
    var image: UIImage?

    override func viewDidLoad() {
        super.viewDidLoad()
        textView.text = response.text ?? ""
        imageView.image = response.image
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
            println(res.text!)
            self?.textView.text = res.text
            self?.activityIndicator.stopAnimating()
        }
        Ladybug.send(request)
    }
    
    @IBAction func done(sender: AnyObject?) {
        dismissViewControllerAnimated(true, completion: nil)
    }

}
