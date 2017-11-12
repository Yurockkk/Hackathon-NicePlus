//
//  ViewController.swift
//  Nice+
//
//  Created by Yubo on 11/11/17.
//  Copyright © 2017 gwu. All rights reserved.
//

import UIKit
import Alamofire


class ViewController: UIViewController {
    
    let parameters: Parameters = [
        "document": [
            "content": "stupid ass",
            "type": "PLAIN_TEXT"
        ],
        "encodingType": "UTF8"
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        Alamofire.request("https://language.googleapis.com/v1/documents:analyzeSentiment?key=AIzaSyCWF1-fJvUSlYBfx9K9HbO9b8ggQcZydk4", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
            print(response)
        })

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

