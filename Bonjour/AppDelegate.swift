//
//  AppDelegate.swift
//  Bonjour
//
//  Created by Artem Maglyovany on 10/30/17.
//  Copyright © 2017 Artem Maglyovany. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    static var shared: AppDelegate? { return UIApplication.shared.delegate as? AppDelegate }
    
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        return true
    }
}
