//
//  AppDelegate.swift
//  Atch
//
//  Created by Alex Barron on 8/2/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import GoogleMaps
import Parse
import Bolts
import FBSDKCoreKit
import FBSDKLoginKit


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        //add googlemaps SDK
        GMSServices.provideAPIKey("AIzaSyANU3A5FMQqMjgdWEYb1uZhXym68Cppc_o")
        
        //add parse SDK
        Parse.setApplicationId("P4g0harOzaQTi9g3QyEqGPI3HkiPJxxz4SJObhCE",
            clientKey: "GpAM5yqJzbltLQENhwJt0cMbrVyM9q4aHR8O3k2s")
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        let userNotificationTypes = (UIUserNotificationType.Alert |
            UIUserNotificationType.Badge |
            UIUserNotificationType.Sound)
        let settings = UIUserNotificationSettings(forTypes: userNotificationTypes, categories: nil)
        application.registerUserNotificationSettings(settings)
        application.registerForRemoteNotifications()
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        

    }
    

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(application: UIApplication,
        openURL url: NSURL,
        sourceApplication: String?,
        annotation: AnyObject?) -> Bool {
            return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)
    }
    
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        let currentInstallation = PFInstallation.currentInstallation()
        currentInstallation.setDeviceTokenFromData(deviceToken)
        currentInstallation.channels = ["global"]
        currentInstallation.saveInBackground()
        println("registered for notifications")
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        println("receiving notification")
        if userInfo["type"] as? String == "message" {
            dealWithMessageNotification(application, userInfo: userInfo)
        }
        if userInfo["type"] as? String == "friendRequest" {
            if application.applicationState != UIApplicationState.Active {
                self.goToAddFriends()
            }
        }
    }
    
    private func dealWithMessageNotification(application: UIApplication, userInfo: [NSObject : AnyObject]) {
        var toUsers = [String]()
        if let curUser = PFUser.currentUser() {
            if let toUserId = userInfo["chatterParseId"] as? String {
                println("working")
                toUsers = [curUser.objectId!, toUserId]
            }
            else { return }
        }
        else {
            self.goToLogin()
            return
        }
        if application.applicationState == UIApplicationState.Active {
            //for now do nothing
            PFPush.handlePush(userInfo)
            NSNotificationCenter.defaultCenter().postNotificationName(messageNotificationReceivedKey, object: self, userInfo: nil)
        }
        else {
            println("inactive")
            self.goToMessages(toUsers)
        }

    }
    
    func getVisibleViewController() -> UIViewController {
        let rootVC = self.window?.rootViewController
        if rootVC!.presentedViewController == nil {
            return rootVC!
        }
        return rootVC!.presentedViewController!
    }
    
    private func goToMessages(toUsers: [String]) {
        
        println("past clauses")
        if getVisibleViewController() is MessagingViewController {
            println("posting notification")
            NSNotificationCenter.defaultCenter().postNotificationName(messageNotificationReceivedKey, object: self, userInfo: ["toUsers":toUsers])
        }
        else {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let messageVC = storyboard.instantiateViewControllerWithIdentifier("MessagingViewController") as! MessagingViewController
            
            if let curUser = PFUser.currentUser() {
                messageVC.toUsers = toUsers
            }
            self.window?.rootViewController?.showViewController(messageVC, sender: nil)
        }
    }
    
    private func goToLogin() {
        if !(getVisibleViewController() is LoginViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            self.window?.rootViewController?.showViewController(loginVC, sender: nil)
        }
    }
    
    private func goToAddFriends() {
        if !(getVisibleViewController() is AddFriendsViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("AddFriendsViewController") as! AddFriendsViewController
            self.window?.rootViewController?.showViewController(loginVC, sender: nil)
        }

    }
    


}

