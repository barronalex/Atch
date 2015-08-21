//
//  FacebookManager.swift
//  
//
//  Created by Alex Barron on 8/14/15.
//
//

import FBSDKCoreKit
import FBSDKLoginKit
import Parse
import Bolts

class FacebookManager {
    
    static func login() {
        let permissions = ["public_profile", "user_friends"]
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
            (user, error) in
            if user == nil {
                if error == nil {
                    println("User cancelled FB login")
                }
                else {
                    println("FB login error: \(error)")
                }
            } else if user!.isNew {
                println("User signed up and logged in with Facebook")
                //if new user fetch and store facebook id
                self.storeUserInfo()
            } else {
                println("User logged in via Facebook")
            }
        }
        println("login done")
    }
    
    static func getFriendList() -> [String] {
        if FBSDKAccessToken.currentAccessToken() != nil {
            //make a call to the graph api, and then query the users on the system by fbid
            let graphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error != nil) {
                    // Process error
                    println("Error: \(error)")
                }
                else {
                    let friends = result.valueForKey("data") as! NSArray
                    println("friends: \(friends)")
                    for friend in friends {
                        friend.valueForKey("id")
                    }
                }
            })
        }
        return []
    }
    
    
    static func storeUserInfo() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error != nil) {
                    // Process error
                    println("Error: \(error)")
                }
                else {
                    println("fetched user: \(result)")
                    let fullname = result.valueForKey("name") as! String
                    println("User Name is: \(fullname)")
                    let id = result.valueForKey("id") as! String
                    println("ID: \(id)")
                    PFUser.currentUser()?.setObject(fullname, forKey: "fullname")
                    PFUser.currentUser()?.setObject(id, forKey: "fbid")
                    PFUser.currentUser()?.saveInBackground()
                }
            })
        }
    }
    
}