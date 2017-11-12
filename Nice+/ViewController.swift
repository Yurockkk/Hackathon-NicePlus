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
    
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let post = "DT SCREW YOU!!! DT LOVE YOU!! DT EAT MY SHIT!! DT is the best!"
        
        self.fetchSentimentScore(inputString: post,completion: {
            results in
            print("\(post) -> score: \(results)")
        })

    }
    
    func fetchSentimentScore(inputString: String, completion: @escaping (Double)-> Void) {
        let text = inputString
        let parameters: Parameters = [
            "document": [
                "content": text,
                "type": "PLAIN_TEXT"
            ],
            "encodingType": "UTF8"
        ]
        Alamofire.request("https://language.googleapis.com/v1/documents:analyzeSentiment?key=AIzaSyCWF1-fJvUSlYBfx9K9HbO9b8ggQcZydk4", method: .post, parameters: parameters, encoding: JSONEncoding.default).responseJSON(completionHandler: { response in
//            print(response)
            guard let datalevel1 = response.result.value as? [String: Any] else {
                print("Error")
                return
            }
//            print(datalevel1)

            guard let dataLevel2 = datalevel1["documentSentiment"] as? [String: Any] else{
                print("error2")
                return
            }
//            print(dataLevel2)
            
            guard let score = dataLevel2["score"] as? Double else{
                return
            }
            
            //printout each sentence
//            dataLevel2.forEach{ sentence in
//                print(sentence)
//                guard let scoreTuple = sentence["sentiment"] as? [String: Any] else{
//                    return
//                }
//                guard let score = scoreTuple["score"] as? Double else {
//                    return
//                }
//
//                print(score)
//            }
            
//            guard let dataLevel3 = dataLevel2[0]["sentiment"] as? [String: Any] else{
//                print("error3")
//                return
//            }
//            guard let scores = dataLevel3["score"] as? Double else{
//                print("score error")
//                return
//            }
            
//            print(scores)
            
            completion(score)
            })
        
        
    }
    

}

