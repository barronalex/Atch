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


let profilePictureNotificationKey = "ab.Atch.profilePictureNotificationKey"

class FacebookManager: FBSDKLoginManager {
    
    var delegate: FacebookManagerDelegate?
    
    func login() {
        let permissions = ["public_profile", "user_friends"]
        if FBSDKAccessToken.currentAccessToken() == nil {
            print("no access")
        }
        PFFacebookUtils.logInInBackgroundWithReadPermissions(permissions) {
            (user, error) in
            if user == nil {
                if error == nil {
                    print("User cancelled FB login")
                }
                else {
                    print("FB login error: \(error)")
                }
            } else if user!.isNew {
                print("User signed up and logged in with Facebook")
                //if new user fetch and store facebook id
                //if new user, we need to get a username
                let installation = PFInstallation.currentInstallation()
                installation.setObject(user!.objectId!, forKey: "userId")
                installation.saveInBackground()
                self.storeUserInfo()
            } else {
                //check if user has username
                let state = user!.objectForKey("usernameSet") as! String
                if state == "f" {
                    self.delegate?.usernameNeeded()
                }
                
                print("User logged in via Facebook")
                self.delegate?.loginFinished()
            }
        }
    }
    
    func getFriendList() -> [String] {
        if FBSDKAccessToken.currentAccessToken() != nil {
            //make a call to the graph api, and then query the users on the system by fbid
            let graphRequest = FBSDKGraphRequest(graphPath: "me/friends", parameters: nil)
            graphRequest.startWithCompletionHandler({ (connection, result, error) -> Void in
                if (error != nil) {
                    // Process error
                    print("Error: \(error)")
                }
                else {
                    let friends = result.valueForKey("data") as! NSArray
                    print("friends: \(friends)")
                    for friend in friends {
                        let id = friend.valueForKey("id") as! String
                        print("Id: \(id)")
                    }
                }
            })
        }
        return []
    }
    
    
    func storeUserInfo() {
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
                    PFUser.currentUser()?.setObject(fullname, forKey: "fullname")
                    PFUser.currentUser()?.setObject(id, forKey: "fbid")
                    PFUser.currentUser()?.saveInBackground()
                }
            })
        }
        self.delegate?.usernameNeeded()
    }
    
    static func downloadProfilePictures(users: [PFObject]) {
        var urlRequests = [NSURLRequest]()
        var pics = [String:UIImage]()
        var reqMap = [NSURLRequest:String]()
        var token = FBSDKAccessToken.currentAccessToken().tokenString
        println("token: \(token)")
        for user in users {
            if let fbid = user.objectForKey("fbid") as? String {
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
                NSNotificationCenter.defaultCenter().postNotificationName(profilePictureNotificationKey, object: nil, userInfo: ["images":pics])
            }
            
        }
        
//        //send data over to somewhere
//
    }
    
}