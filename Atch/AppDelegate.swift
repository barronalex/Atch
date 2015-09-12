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
import CoreData


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?


    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        
        if let currentUser = PFUser.currentUser() {
            PFInstallation.currentInstallation().setObject(currentUser.objectId!, forKey: "userId")
            PFInstallation.currentInstallation().saveInBackground()
        }
        
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
        _mapView?.myLocationEnabled = false
        _mapView?.settings.myLocationButton = false
    }

    func applicationWillEnterForeground(application: UIApplication) {
        PFInstallation.currentInstallation().setObject(0, forKey: "badge")
        PFInstallation.currentInstallation().saveInBackground()
        _mapView?.myLocationEnabled = true
        _mapView?.settings.myLocationButton = true
    }
    

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        self.saveContext()
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
        let curVC = getVisibleViewController(self.window?.rootViewController)
        if curVC is LoginViewController {
            return
        }
        if userInfo["type"] as? String == "message" {
            dealWithMessageNotification(application, userInfo: userInfo)
        }
        if userInfo["type"] as? String == "friendRequest" {
            if application.applicationState != UIApplicationState.Active {
                Navigator.goToAddFriends()
            }
            else {
                let aps = userInfo["aps"] as! [NSObject : AnyObject]
                if let text = aps["alert"] as? String {
                    _notificationBanner.displayNotification(text, type: "friendRequest", toUsers: [String]())
                }
            }
        }
        if userInfo["type"] as? String == "friendAccept" {
            if application.applicationState != UIApplicationState.Active {
                Navigator.goToFriends()
            }
            else {
                let aps = userInfo["aps"] as! [NSObject : AnyObject]
                if let text = aps["alert"] as? String {
                    _notificationBanner.displayNotification(text, type: "friendAccept", toUsers: [String]())
                }
            }
        }
    }
    
    private func getToUsersFromNotification(userInfo: [NSObject : AnyObject]) -> [String]? {
        if let curUser = PFUser.currentUser() {
            if let toUserId = userInfo["chatterParseId"] as? String {
                println("working")
                return [toUserId]
            }
            else { return nil }
        }
        else {
            Navigator.goToLogin()
            return nil
        }
    }
    
    private func dealWithMessageNotification(application: UIApplication, userInfo: [NSObject : AnyObject]) {
        var toUsers = getToUsersFromNotification(userInfo)
        if toUsers == nil { return }
        if let atchVC = getVisibleViewController(self.window?.rootViewController) as? AtchMapViewController {
            println("USERS: \(atchVC.containerVC!.toUsers)")
            println("Other USERS: \(toUsers!)")
            if atchVC.bannerAtTop && atchVC.containerVC!.toUsers == toUsers! {
                println("broadcasting notification")
                NSNotificationCenter.defaultCenter().postNotificationName(messageNotificationReceivedKey, object: self, userInfo: nil)
                return
            }
            
        }
        if application.applicationState == UIApplicationState.Active {
            let curVC = getVisibleViewController(self.window?.rootViewController)
            if curVC is LoginViewController || curVC is IntroViewController {
                return
            }
            let aps = userInfo["aps"] as! [NSObject : AnyObject]
            
            if let text = aps["alert"] as? String {
                //let goodtext = String(text)
                _notificationBanner.displayNotification(text, type: "message", toUsers: toUsers!)
            }
        
        }
        else {
            println("inactive")
            Navigator.goToMessages(toUsers!)
        }

    }
    
    func getVisibleViewController(rootVC: UIViewController?) -> UIViewController {
        if rootVC!.presentedViewController == nil {
            return rootVC!
        }
        return getVisibleViewController(rootVC!.presentedViewController)
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.xxxx.ProjectName" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1] as! NSURL
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("UserColourDataModel", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("Atch.sqlite")
        var error: NSError? = nil
        var failureReason = "There was an error creating or loading the application's saved data."
        if coordinator!.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil, error: &error) == nil {
            coordinator = nil
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            dict[NSUnderlyingErrorKey] = error
            error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(error), \(error!.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        if coordinator == nil {
            return nil
        }
        var managedObjectContext = NSManagedObjectContext()
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if let moc = self.managedObjectContext {
            var error: NSError? = nil
            if moc.hasChanges && !moc.save(&error) {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                NSLog("Unresolved error \(error), \(error!.userInfo)")
                abort()
            }
        }
    }
    
}

