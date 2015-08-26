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
                println("facebook login error: \(error)")
                self.delegate?.facebookLoginFailed("error")

            }
            else if result.isCancelled {
                println("Login was cancelled")
                self.delegate?.facebookLoginFailed("Login was cancelled")
            }
            else if (result.grantedPermissions.contains("public_profile") && result.grantedPermissions.contains("user_friends")) {
                println("user granted permissions")
                self.delegate?.facebookLoginSucceeded()
            }
            else {
                println("not enough permissions were granted")
                self.delegate?.facebookLoginFailed("not enough permissions were granted")
            }
        }

    }
    
    
    private func storeUserInfo() {
        if FBSDKAccessToken.currentAccessToken() != nil {
            let graphRequest = FBSDKGraphRequest(graphPath: "me", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error != nil) {
                    // Process error
                    print("Error: \(error)")
                }
                else {
                    print("fetched user: \(result)")
                    let fullname = result.valueForKey("name") as! String
                    print("User Name is: \(fullname)")
                    let id = result.valueForKey("id") as! String
                    print("ID: \(id)")
                    PFUser.currentUser()?.setObject(fullname, forKey: parse_user_fullname)
                    PFUser.currentUser()?.setObject(fullname.lowercaseString, forKey: parse_user_queryFullname)
                    PFUser.currentUser()?.setObject(id, forKey: parse_user_fbid)
                    PFUser.currentUser()?.saveInBackground()
                    self.delegate?.parseLoginSucceeded()
                }
            })
        }
    }
    
    static func downloadProfilePictures(users: [PFObject]) {
        var urlRequests = [NSURLRequest]()
        var pics = [String:UIImage]()
        var reqMap = [NSURLRequest:String]()
        var token = FBSDKAccessToken.currentAccessToken().tokenString
        println("token: \(token)")
        for user in users {
            if let fbid = user.objectForKey(parse_user_fbid) as? String {
                let url = NSURL(string: "https://graph.facebook.com/\(fbid)/picture?type=square")
                let request = NSURLRequest(URL: url!)
                urlRequests.append(request)
                reqMap[request] = user.objectId!
            }
        }
        var outstandingRequests = urlRequests.count
        
        
        
        var callerQueue = dispatch_get_main_queue()
        var downloadQueue = dispatch_queue_create("requests", nil)
        dispatch_async(downloadQueue) {
            for request in urlRequests {
                if let data = NSURLConnection.sendSynchronousRequest(request, returningResponse: nil, error: nil) {
                    println("here")
                    var image = UIImage(data: data)
                    println("image: \(image)")
                    pics[reqMap[request]!] = image
                }
            }
            dispatch_async(callerQueue) {
                println("done")
                _friendManager.friendPics += pics
                NSNotificationCenter.defaultCenter().postNotificationName(profilePictureNotificationKey, object: nil, userInfo: nil)
            }
            
        }
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
                        let installation = PFInstallation.currentInstallation()
                        installation.setObject(PFUser.currentUser()!.objectId!, forKey: parse_installation_userId)
                        installation.saveInBackground()
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
                println("parse login failed - this should never happen")
                self.delegate?.parseLoginFailed()
            }
            else if user!.isNew {
                println("login succeeded")
                self.delegate?.parseLoginSucceeded()
            }
            else {
                println("user has already signed up")
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
                            println("error in fbid parse query: \(error)")
                        }
                        else {
                            if let user = user {
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