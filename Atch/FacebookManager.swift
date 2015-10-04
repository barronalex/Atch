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
    
    var delegate: FacebookManagerDelegate?
    var manager = FBSDKLoginManager()
   
    
    func login() {
        let permissions = ["public_profile", "user_friends"]
        if FBSDKAccessToken.currentAccessToken() == nil {
            print("no access")
        }
        
        manager.logInWithReadPermissions(permissions) {
            (result, error) in
            if error != nil {
                print("facebook login error: \(error)")
                self.delegate?.facebookLoginFailed("error")

            }
            else if result.isCancelled {
                print("Login was cancelled")
                self.delegate?.facebookLoginFailed("Login was cancelled")
            }
            else if (result.grantedPermissions.contains("public_profile") && result.grantedPermissions.contains("user_friends")) {
                print("user granted permissions")
                self.delegate?.facebookLoginSucceeded()
            }
            else {
                print("not enough permissions were granted")
                self.delegate?.facebookLoginFailed("not enough permissions were granted")
            }
        }

    }
    
    
    private func storeUserInfo() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequestMe = FBSDKGraphRequest(graphPath: "/me?fields=id,name,first_name", parameters: nil)
            graphRequestMe.startWithCompletionHandler({
                (connection, result, error) -> Void in
                if (error != nil) {
                    // Process error
                    print("Error: \(error)")
                }
                else {
                    print("fetched user: \(result)")
                    if let fullname = result.valueForKey("name") as? String {
                        PFUser.currentUser()?.setObject(fullname, forKey: parse_user_fullname)
                        PFUser.currentUser()?.setObject(fullname.lowercaseString, forKey: parse_user_queryFullname)
                    }
                    else {
                        self.delegate?.parseLoginFailed()
                        return
                    }
                    if let id = result.valueForKey("id") as? String {
                        PFUser.currentUser()?.setObject(id, forKey: parse_user_fbid)
                    }
                    else {
                        self.delegate?.parseLoginFailed()
                        return
                    }
                    if let firstname = result.valueForKey("first_name") as? String {
                        PFUser.currentUser()?.setObject(firstname, forKey: "firstname")
                    }
                    else {
                        self.delegate?.parseLoginFailed()
                        return
                    }
                    PFUser.currentUser()?.saveInBackground()
                    self.delegate?.parseLoginSucceeded()
                }
                
            })
        }
    }
    
    static func downloadProfilePictures(users: [PFObject]) {
        let session = NSURLSession.sharedSession()
        for user in users {
            print("looping through users")
            if let fbid = user.objectForKey(parse_user_fbid) as? String {
                print("inside iflet")
                let url = NSURL(string: "https://graph.facebook.com/\(fbid)/picture?width=200&height=200")
                let request = NSURLRequest(URL: url!)
                session.dataTaskWithRequest(request, completionHandler: {
                    (data, response, error) -> Void in
                    if error == nil {
                        if let data = data {
                            print("here")
                            let image = UIImage(data: data)
                            print("image: \(image)")
                            _friendManager.userMap[user.objectId!]?.image = image
                            NSNotificationCenter.defaultCenter().postNotificationName(profilePictureNotificationKey, object: nil, userInfo: nil)
                        }
                    }
                    else {
                        print("PICTURE ERROR")
                    }

                }).resume()
                
            }
        }
       
        print("done")
        NSNotificationCenter.defaultCenter().postNotificationName(profilePictureNotificationKey, object: nil, userInfo: nil)
        //_friendManager.downloadedPics = true
        
        
    }
    
    
    func loginUserToParseWithoutToken() {
        let permissions = ["public_profile", "user_friends"]
                PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
                    (user, error) in
                    if user == nil {
                        if error == nil {
                            print("User cancelled FB login")
                            self.delegate?.parseLoginFailed()
                        }
                        else {
                            self.delegate?.parseLoginFailed()
                            print("FB login error: \(error)")
                        }
                    } else if user!.isNew {
                        print("User signed up and logged in with Facebook")
                        //if new user fetch and store facebook id
                        self.storeUserInfo()
                    } else {
                        //check if user has username
                        print("User logged in via Facebook")
                        self.delegate?.alreadySignedUp()
                    }
                }
    }
    
    func loginUserToParseWithToken() {
        PFFacebookUtils.logInInBackgroundWithAccessToken(FBSDKAccessToken.currentAccessToken()) {
            (user, error) in
            if user == nil || error != nil {
                print("parse login failed - this should never happen")
                self.delegate?.parseLoginFailed()
            }
            else if user!.isNew {
                print("login succeeded")
                self.delegate?.parseLoginSucceeded()
            }
            else {
                print("user has already signed up")
                self.delegate?.parseLoginSucceeded()
            }
        }
    }
    
    func checkIfFacebookAssociatedWithParse() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
            graphRequest.startWithCompletionHandler({
                (connection, result, error) -> Void in
                if (error != nil) {
                    // Process error
                    print("Error: \(error)")
                }
                else {
                    print("fetched user: \(result)")
                    let id = result.valueForKey("id") as! String
                    print("ID: \(id)")
                    //query parse for id
                    let query = PFUser.query()!
                    query.whereKey(parse_user_fbid, equalTo: id)
                    query.getFirstObjectInBackgroundWithBlock() {
                        (user, error) in
                        if error != nil {
                            print("error in fbid parse query: \(error)")
                            self.delegate?.facebookLoginFailed("Must have an account to log in - click sign up")
                        }
                        else {
                            if let _ = user {
                                //if user already has a parse account
                                self.loginUserToParseWithToken()
                            }
                            else {
                                self.delegate?.goToSignUp()
                            }
                        }
                    }
                }
            })
        }
    }
    
}