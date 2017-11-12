//
//  ViewController.swift
//  Nice+
//
//  Created by Yubo on 11/11/17.
//  Copyright © 2017 gwu. All rights reserved.
//

import UIKit
import Alamofire
import FacebookCore
import FacebookLogin

class ViewController: UIViewController {
    
    

    lazy var loginButton: LoginButton = {
        return LoginButton(readPermissions: [.publicProfile, .email, .userFriends, .userPosts])
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let post = "DT SCREW YOU!!! DT LOVE YOU!! DT EAT MY SHIT!! DT is the best!"
        
        self.fetchSentimentScore(inputString: post,completion: {
            (content, score) in
            print("\(content) -> score: \(score)")
        })
        self.loginButton.center = self.view.center
        self.view.addSubview(self.loginButton)
        self.fetchPosts()
    }
    
    func fetchSentimentScore(inputString: String, completion: @escaping (_ negativeContent: String, _ score: Double)-> Void) {
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

            guard let dataLevel2 = datalevel1["sentences"] as? [[String: Any]] else{
                print("error2")
                return
            }
//            print(dataLevel2)
            
//            guard let score = dataLevel2["score"] as? Double else{
//                return
//            }
            
            //printout each sentence
            var mostNegativeContent = ""
            var mostNegativeScore = 100.0
            
            dataLevel2.forEach{ sentence in
//                print(sentence)
                guard let scoreTuple = sentence["sentiment"] as? [String: Any] else{
                    print("error scoreTuple")

                    return
                }
                guard let score = scoreTuple["score"] as? Double else {
                    print("error score")

                    return
                }
                guard let textTuple = sentence["text"] as? [String: Any] else{
                    print("error textTuple")
                    return
                }
                guard let text = textTuple["content"] as? String else{
                    print("error text")
                    return
                }
                if(score < mostNegativeScore){
                    mostNegativeScore = score
                    mostNegativeContent = text
                }
                print("\(text) : \(score)")
            }
            
//            guard let dataLevel3 = dataLevel2[0]["sentiment"] as? [String: Any] else{
//                print("error3")
//                return
//            }
//            guard let scores = dataLevel3["score"] as? Double else{
//                print("score error")
//                return
//            }
            
//            print(scores)
            
            completion(mostNegativeContent,mostNegativeScore)
            })
    }
    

    private func fetchPosts() {
        guard AccessToken.current?.userId != nil else {
            print("No valid user data")
            return
        }
        
        let connection = GraphRequestConnection()
        connection.add(MyPostRequest()) {
            response, result in
            switch result {
            case .success(response: let _response):
//                print("ID Counts: \(_response.postIDs.count)")
//                print(_response.postIDs)
//                print("Msg Counts: \(_response.postMsgs.count)")
//                print(_response.postMsgs)
                // Test Using PostID to fetch comments
                self.fetchComments(postID: _response.postIDs[0])
            case .failed(let error):
                print("Failed to request user profile: \(error.localizedDescription)")
            }
        }
        connection.start()
    }
    
    private func fetchComments(postID: String) {
        guard AccessToken.current?.userId != nil else {
            print("No valid user data")
            return
        }
        
        let connenction = GraphRequestConnection()
        connenction.add(MyCommentsRequest(postID: postID)) {
            response, result in
            switch result {
            case .success(response: let _response):
                print(_response.userComments)
            case .failed(let error):
                print("Failed to request comment: \(error.localizedDescription)")
            }
        }
        connenction.start()
        
    }
}

extension ViewController {
    struct MyPostRequest: GraphRequestProtocol {
        struct Response: GraphResponseProtocol {
            var postMsgs = [String]()
            var postIDs = [String]()
            
            init(rawResponse: Any?) {
                guard let response = rawResponse as? Dictionary<String, Any> else {
                    print("Failed to parse rawResponse")
                    return
                }
                
                guard let dataArr = response["data"] as? [[String: Any]] else {
                    print("Failed to parse dict data")
                    return
                }
                
                for data in dataArr {
                    if data["message"] != nil {
                        guard let message = data["message"] as? String else {
                            print("Failed to parse message")
                            return
                        }
                        
                        guard let id = data["id"] as? String else {
                            print("Failed to parse post id")
                            return
                        }
                        
                        postMsgs.append(message)
                        postIDs.append(id)
                    }
                }
            }
        }
        
        var graphPath = "/me/posts"
        var parameters: [String : Any]?
        var accessToken = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
    }
    
    struct MyCommentsRequest: GraphRequestProtocol {
        init(postID: String) {
            self.graphPath = "\(postID)/comments"
        }
        
        struct Response: GraphResponseProtocol {
            var commentIDs = [String]()
            var userComments = [String]()
            
            init(rawResponse: Any?) {
                guard let response = rawResponse as? Dictionary<String, Any> else {
                    print("Failed to parse rawResponse")
                    return
                }
                
                guard let dataArr = response["data"] as? [[String: Any]] else {
                    print("Failed to parse data")
                    return
                }
                for data in dataArr {
                    if data["message"] != nil {
                        guard let message = data["message"] as? String else {
                            print("Failed to parse comment message")
                            return
                        }
                        
                        guard let commentID = data["id"] as? String else {
                            print("Failed to parse comment id")
                            return
                        }
                        
                        commentIDs.append(commentID)
                        userComments.append(message)
                    }
                }
            }
        }
        
        var graphPath = ""
        var parameters: [String : Any]?
        var accessToken = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
    }
}

