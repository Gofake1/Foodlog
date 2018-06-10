//
//  AppDelegate.swift
//  Foodlog
//
//  Created by David on 12/12/17.
//  Copyright © 2017 Gofake1. All rights reserved.
//

import UIKit

@UIApplicationMain
final class AppDelegate: UIResponder {
    var window: UIWindow?
}

extension AppDelegate: UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
    {
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = VCController.pulleyVC
        window!.makeKeyAndVisible()
        application.registerForRemoteNotifications()
        CloudStore.setup(onAccountChange: {
            if let error = $0 {
                UIApplication.shared.alert(error: error)
            }
        })
        return true
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        UIApplication.shared.alert(error: error)
    }
    
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void)
    {
        CloudStore.received(remoteNotificationInfo: userInfo) {
            if let error = $0 {
                completionHandler(.failed)
                UIApplication.shared.alert(error: error)
            } else {
                completionHandler(.newData)
            }
        }
    }
}
