//
//  AppDelegate.swift
//  Nice+
//
//  Created by Yubo on 11/11/17.
//  Copyright © 2017 gwu. All rights reserved.
//

import UIKit
import FacebookCore
import FacebookLogin

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Facebook Delegate Setting
        SDKApplicationDelegate.shared.application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        SDKApplicationDelegate.shared.application(app, open: url, options: options)
        
        return true
    }


}

