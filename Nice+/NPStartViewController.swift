//
//  NPStartViewController.swift
//  Nice+
//
//  Created by YiChen Zhou on 11/12/17.
//  Copyright © 2017 gwu. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

class NPStartViewController: UIViewController {

    @IBOutlet weak var segueButton: UIButton!
    lazy var loginButton: UIButton = {
        return UIButton()
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.setup()
    }
    
    private func setup() {
        self.loginButton.frame = CGRect(x: 0, y: 0, width: 200, height: 35)
        self.loginButton.center = self.view.center
        self.loginButton.backgroundColor = kFacebookColor
        self.loginButton.addTarget(self, action: #selector(self.loginButtonPressed(_:)), for: .touchUpInside)
        self.view.addSubview(self.loginButton)
        
        if AccessToken.current != nil {
            // Login already
            self.loginButton.setTitle("Press to sign out", for: .normal)
            self.segueButton.setTitle("Press To Be Nice+!", for: .normal)
            self.segueButton.isUserInteractionEnabled = true
        } else {
            // Not Login yet
            self.loginButton.setTitle("Press to sign in", for: .normal)
            self.segueButton.setTitle("Please Login First", for: .normal)
            self.segueButton.isUserInteractionEnabled = false
        }
    }
    
    @objc private func loginButtonPressed(_ sender: Any) {
        let loginManager = LoginManager()
        if AccessToken.current == nil {
            loginManager.logIn(readPermissions: [.publicProfile, .email, .userFriends, .userPosts], viewController: self, completion: {
                loginResult in
                switch loginResult {
                case .failed(let error):
                    print("Failed to login Facebook: \(error.localizedDescription)")
                case .cancelled:
                    break
                case .success(_, _, _):
                    let connection = GraphRequestConnection()
                    connection.add(MyProfileRequest()) {
                        response, result in
                        switch result {
                        case .success(response: let _response):
                            if let userID = _response.id {
                                UserDefaults.standard.set(userID, forKey: "userID")
                            }
                            
                            if let userName = _response.name {
                                UserDefaults.standard.set(userName, forKey: "userName")
                            }
                            
                            if let email = _response.email {
                                UserDefaults.standard.set(email, forKey: "userEmail")
                            }
                            
                            if let imageURL = _response.imageURL {
                                UserDefaults.standard.set(imageURL, forKey: "imageURL")
                            }
                            
                        case .failed(let error):
                            print("Failed to request user profile: \(error.localizedDescription)")
                        }
                    }
                    connection.start()
                }
            })
        } else {
            loginManager.logOut()
            UserDefaults.standard.removeObject(forKey: "userID")
            UserDefaults.standard.removeObject(forKey: "userName")
            UserDefaults.standard.removeObject(forKey: "userEmail")
            UserDefaults.standard.removeObject(forKey: "imageURL")
            self.loginButton.setTitle("Press to sign in", for: .normal)
            self.segueButton.setTitle("Please Login First", for: .normal)
            self.segueButton.isUserInteractionEnabled = false
        }
  }
}

extension NPStartViewController {
    struct MyProfileRequest: GraphRequestProtocol {
        struct Response: GraphResponseProtocol {
            var name: String?
            var id: String?
            var email: String?
            var imageURL: String?
            
            init(rawResponse: Any?) {
                guard let response = rawResponse as? Dictionary<String, Any> else {
                    print("Failed to parse rawResponse")
                    return
                }
                
                guard let name = response["name"] as? String else {
                    print("Failed to parse name")
                    return
                }
                self.name = name
                
                guard let id = response["id"] as? String else {
                    print("Failed to parse id")
                    return
                }
                self.id = id
                
                guard let email = response["email"] as? String else {
                    print("Failed to parse email")
                    return
                }
                self.email = email
                
                guard let imageInfo = response["picture"] as? [String: Any] else {
                    print("Failed to parse profile image info")
                    return
                }
                
                guard let imageInfoData = imageInfo["data"] as? [String: Any] else {
                    print("Failed to parse profile image info data")
                    return
                }
                
                guard let url = imageInfoData["url"] as? String else {
                    print("Failed to parse profile image url")
                    return
                }
                
                self.imageURL = url
            }
        }
        var graphPath = "/me"
        var parameters: [String : Any]? = ["fields": "id, name, email, picture.type(large)"]
        var accessToken = AccessToken.current
        var httpMethod: GraphRequestHTTPMethod = .GET
        var apiVersion: GraphAPIVersion = .defaultVersion
    }
}
