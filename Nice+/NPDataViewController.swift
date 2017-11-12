//
//  NPDataViewController.swift
//  Nice+
//
//  Created by YiChen Zhou on 11/12/17.
//  Copyright © 2017 gwu. All rights reserved.
//

import UIKit
import Alamofire
import FacebookCore
import FacebookLogin

class NPDataViewController: UIViewController {
    @IBOutlet weak var dataTableView: UITableView!
    @IBOutlet weak var userImageView: UIImageView!
    @IBOutlet weak var userNameLabel: UILabel!
    
    var refresher: UIRefreshControl?
    var postArr = [String]()
    var scoreArr = [Double]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.refresher = UIRefreshControl()
        self.refresher?.attributedTitle = NSAttributedString(string: "Pull To Refresh")
        self.refresher?.addTarget(self, action: #selector(self.refreshData), for: .valueChanged)
        self.dataTableView.addSubview(self.refresher!)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fetchUserImage()
        self.refreshData()
    }
    
    @objc private func refreshData() {
        guard AccessToken.current?.userId != nil else {
            print("No valid user data")
            return
        }
        
        if let userName = UserDefaults.standard.value(forKey: "userName") as? String {
            self.userNameLabel.text = userName
        } else {
            self.userNameLabel.text = "Mr. Robot"
        }
        
        let connection = GraphRequestConnection()
        connection.add(MyPostRequest()) {
            response, result in
            switch result {
            case .success(response: let _response):
                // Test Using PostID to fetch comments
                self.postArr = _response.postMsgs
                self.scoreArr = Array(repeating: 0.0, count: self.postArr.count)
                self.refresher?.endRefreshing()
                self.dataTableView.reloadData()
                for item in self.postArr.enumerated() {
                    self.fetchSetimentScore(text: item.element, completion: {
                        content, score in
                        self.scoreArr[item.offset] = score
                    })
                }
                self.dataTableView.reloadData()
            case .failed(let error):
                print("Failed to request user profile: \(error.localizedDescription)")
            }
        }
        connection.start()
    }
    
    @objc private func fetchSetimentScore(text: String, completion: @escaping(_ analysiedContent: String, _ score: Double) -> Void) {
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
            
            guard let dataLevel2 = datalevel1["sentences"] as? [[String: Any]] else{
                print("error2")
                return
            }
            
            var mostNegativeContent = ""
            var mostNegativeScore = 100.0
            
            dataLevel2.forEach{
                sentence in
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
            }
            
            completion(mostNegativeContent,mostNegativeScore)
        })
    }
    
    private func fetchUserImage() {
        guard let imageURL = UserDefaults.standard.value(forKey: "imageURL") as? String else {
            print("Failed to get imageURL from UserDefaults")
            return
        }
        
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let fileURL = documentsURL.appendingPathComponent("userProfileImage")
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        Alamofire.download(imageURL, to: destination).responseData(completionHandler: {
            response in
            guard let data = response.result.value else {
                print("Invalid data type for response")
                return
            }
            let image = UIImage(data: data)
            DispatchQueue.main.async {
                self.userImageView.image = image
                self.userImageView.layer.cornerRadius = 50
                self.userImageView.clipsToBounds = true
            }
        })
    }
}

extension NPDataViewController {
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

extension NPDataViewController: UITableViewDelegate {
    
}

extension NPDataViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.postArr.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NPTextCell", for: indexPath) as! NPTextCell
        cell.postTextLabel.text = self.postArr[indexPath.row]
        let score = self.scoreArr[indexPath.row]
        if score <= 1.0 && score >= 0.75 {
            cell.actionButton.isHidden = false
            cell.backgroundColor = kGreenColor
        } else if score < 0.75 && score >= 0.25 {
            cell.actionButton.isHidden = false
            cell.backgroundColor = kLightGreenColor
        } else if score < 0.25 && score >= -0.25 {
            cell.backgroundColor = kYellowColor
            cell.actionButton.isHidden = true
        } else if score < -0.25 && score >= -0.75 {
            cell.backgroundColor = kLightRedColor
            cell.actionButton.isHidden = true
        } else {
            cell.backgroundColor = kRedColor
            cell.actionButton.isHidden = true
        }
        return cell
    }
}
