//
//  AppDelegate.swift
//  Foodlog
//
//  Created by David on 12/12/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder {
    var window: UIWindow?
}

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = VCController.pulleyVC
        window!.makeKeyAndVisible()
        return true
    }
}

extension UIApplication {
    func alert(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
    
    func alert(warning warningString: String, confirm userConfirmationHandler: @escaping () -> ()) {
        let alert = UIAlertController(title: "Warning", message: warningString, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Confirm", style: .destructive, handler: { _ in
            userConfirmationHandler()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
    }
}
