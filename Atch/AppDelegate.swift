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
        //if userInfo["type"] as? String == "message" {
            dealWithMessageNotification(application, userInfo: userInfo)
        //}
        if userInfo["type"] as? String == "friendRequest" {
            if application.applicationState != UIApplicationState.Active {
                self.goToAddFriends()
            }
        }
    }
    
    private func getToUsersFromNotification(userInfo: [NSObject : AnyObject]) -> [String]? {
        if let curUser = PFUser.currentUser() {
            if let toUserId = userInfo["chatterParseId"] as? String {
                println("working")
                return [curUser.objectId!, toUserId]
            }
            else { return nil }
        }
        else {
            self.goToLogin()
            return nil
        }
    }
    
    private func dealWithMessageNotification(application: UIApplication, userInfo: [NSObject : AnyObject]) {
        var toUsers = getToUsersFromNotification(userInfo)
        if toUsers == nil { return }
        if application.applicationState == UIApplicationState.Active {
            //for now do nothing
            if let atchVC = getVisibleViewController(self.window?.rootViewController) as? AtchMapViewController {
                if atchVC.bannerAtTop && atchVC.containerVC!.toUsers == toUsers! {
                    NSNotificationCenter.defaultCenter().postNotificationName(messageNotificationReceivedKey, object: self, userInfo: nil)
                    return
                }
            }
            PFPush.handlePush(userInfo)
           
            
        }
        else {
            println("inactive")
            self.goToMessages(toUsers!)
        }

    }
    
    func getVisibleViewController(rootVC: UIViewController?) -> UIViewController {
        if rootVC!.presentedViewController == nil {
            return rootVC!
        }
        return getVisibleViewController(rootVC!.presentedViewController)
    }
    
    private func goToMessages(toUsers: [String]) {
        
        println("past clauses")
        if let atchVC = getVisibleViewController(self.window?.rootViewController) as? AtchMapViewController {
            println("ATCH MAP CONTROLLER PRESENTED")
            atchVC.tappedUserId = toUsers[1]
            atchVC.containerVC?.goToMessages(toUsers)
            atchVC.bringUpMessagesScreen()
        }
        else if let introVC = getVisibleViewController(self.window?.rootViewController) as? IntroViewController { }
        else if let friendsVC = getVisibleViewController(self.window?.rootViewController) as? FriendsViewController {
            println("FRIEND VIEWCONTROLLER PRESENTED")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let atchVC = storyboard.instantiateViewControllerWithIdentifier("AtchMapViewController") as! AtchMapViewController
            getVisibleViewController(self.window?.rootViewController).showViewController(atchVC, sender: nil)
            atchVC.tappedUserId = toUsers[1]
            atchVC.containerVC?.goToMessages(toUsers)
            atchVC.bringUpMessagesScreen()
            if let friendLocation = _friendManager.userMarkers[toUsers[1]]?.position {
                println("animating")
                atchVC.mapView!.animateToLocation(friendLocation)
            }
            
        }
    }
    
    private func goToLogin() {
        if !(getVisibleViewController(self.window?.rootViewController) is LoginViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            getVisibleViewController(self.window?.rootViewController).showViewController(loginVC, sender: nil)
        }
    }
    
    private func goToAddFriends() {
        if !(getVisibleViewController(self.window?.rootViewController) is AddFriendsViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("AddFriendsViewController") as! AddFriendsViewController
            getVisibleViewController(self.window?.rootViewController).showViewController(loginVC, sender: nil)
        }

    }
    


}

