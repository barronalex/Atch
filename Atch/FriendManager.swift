//
//  FriendManager.swift
//  
//
//  Created by Alex Barron on 8/14/15.
//
//

import Foundation
import Parse
import Bolts
import FBSDKCoreKit
import GoogleMaps
import CoreData

class FriendManager {
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    var delegate: FriendManagerDelegate?
    
    var userMap = [String:User]()
    var friends = [PFUser]()
    var groups = [Group]()
    var groupMap = [String:Group]()
    var downloadedPics = false
    
    var lastFriendData = [PFObject]()
    
    var readyForAtch = false
    
    func sendRequest(targetUserID: String) {
        //gets user from id
        let targetUser = PFUser.objectWithoutDataWithObjectId(targetUserID)
        
        //checks if duplicate
        let query = PFQuery(className: "FriendRequest")
        query.whereKey(parse_friendRequest_toUser, equalTo: targetUser)
        
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects as? [PFObject] {
                    if objects.count == 0 {
                        let req = self.createRequest(targetUser)
                        self.delegate?.friendRequestSent(req, userId: targetUserID)
                    }
                    else {
                        print("duplicate request")
                    }
                }
                
                
            } else {
                print("error in sending request")
                
            }
            
        }
    }
    
    func createRequest(targetUser: PFUser) -> PFObject {
        let friendRequest = PFObject(className: "FriendRequest")
        friendRequest.setObject(PFUser.currentUser()!, forKey: parse_friendRequest_fromUser)
        friendRequest.setObject(targetUser, forKey: parse_friendRequest_toUser)
        friendRequest.setObject("requested", forKey: parse_friendRequest_state)
        friendRequest.saveInBackground()
        return friendRequest
    }
    
    func acceptRequest(friendId: String) {
        let friend = PFUser.objectWithoutDataWithObjectId(friendId)
        let query = PFQuery(className: "FriendRequest")
        query.whereKey(parse_friendRequest_toUser, equalTo: PFUser.currentUser()!)
        query.whereKey(parse_friendRequest_fromUser, equalTo: friend)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects as? [PFObject] {
                    for object in objects {
                        object.setObject("accepted", forKey: parse_friendRequest_state)
                        object.saveInBackground()
                    }
                }
            }
            else {
                print("error in getting pending requests")
            }
        }
    }
    
    func acceptRequest(request: PFObject) {
        request.setObject("accepted", forKey: parse_friendRequest_state)
        request.saveInBackground()
    }
    
    //what do I need to load:
    //pending requests, including the user objects associated with them
    //friends
    //facebook friends on the app
    
    func getPendingRequests(fromUser: Bool) {
        
        var result = [String]()
        let query = PFQuery(className: "FriendRequest")
        if fromUser {
            query.whereKey(parse_friendRequest_fromUser, equalTo: PFUser.currentUser()!)
        }
        else {
            query.whereKey(parse_friendRequest_toUser, equalTo: PFUser.currentUser()!)
        }
        query.whereKey(parse_friendRequest_state, equalTo: "requested")
        if fromUser {
            query.orderByAscending(parse_friendRequest_toUser)
        }
        else {
            query.orderByAscending(parse_friendRequest_fromUser)

        }
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let requests = objects as? [PFObject] {
                    for request in requests {
                        print(request.objectId!)
                        result.append(request.objectId!)
                    }
                    //get users from requests
                    let count = requests.count
                    print("Count: \(count)")
                    self.getUsersFromRequests(requests, fromUser: fromUser)
                }
            }
            else {
                print("error in getting pending requests")
            }
        }
        
    }
    
    func getUsersFromRequests(requests: [PFObject], fromUser: Bool) {
        print("getting users")
        let count = requests.count
        print("Count: \(count)")
        var userIds = [String]()
        for request in requests {
            if fromUser {
                let pendingFriend = request[parse_friendRequest_toUser] as! PFObject
                userIds.append(pendingFriend.objectId!)
            }
            else {
                let pendingFriend = request[parse_friendRequest_fromUser] as! PFObject
                userIds.append(pendingFriend.objectId!)
            }
        }
        let query = PFUser.query()!
        query.whereKey("objectId", containedIn: userIds)
        query.orderByAscending("objectId")
        query.findObjectsInBackgroundWithBlock {
            (pendingFriends: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let pendingFriends = pendingFriends as? [PFUser] {
                    //sort requests and users so that they are in same order
                    
                    if fromUser {
                        self.delegate?.pendingFromRequestsFound(requests, users: pendingFriends)
                        self.addUsersToMap(pendingFriends, type: UserType.PendingFrom)
                    }
                    else {
                        FacebookManager.downloadProfilePictures(pendingFriends)
                        self.delegate?.pendingToRequestsFound(requests, users: pendingFriends)
                        self.addUsersToMap(pendingFriends, type: UserType.PendingTo)
                    }
                    
                }
            } else {
                print("error in GETTING PENDING USERS request")
                
            }
        }

    }
    
    func addUsersToMap(parseObjects: [PFObject], type: UserType) {
        
        for object in parseObjects {
            if let user = self.userMap[object.objectId!] {
                //if user already exists, change their flag if necessary
                if type.rawValue < user.type.rawValue {
                    user.type = type
                    println("user id: \(object.objectId!)")
                    self.userMap[object.objectId!] = user
                }
            }
            else {
                var user = User(type: type, parseObject: object)
                //add colour
                user = addColourToUser(user)
                self.userMap[object.objectId!] = user
            }
            
            
        }
    }
    
    func changeUserColour(user: User) {
        let fetchRequest = NSFetchRequest(entityName: "UserColour")
        let predicate = NSPredicate(format: "userId == %@", user.parseObject!.objectId!)
        fetchRequest.predicate = predicate
        let colour = ColourGenerator.generateRandomColour()
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [UserColour] {
            if fetchResults.count > 0 {
                println("inside if statement")
                fetchResults[0].colour = colour
            }
            else {
                println("did not find colour")
                //if not make new object
                let newUserColour = NSEntityDescription.insertNewObjectForEntityForName("UserColour", inManagedObjectContext: self.managedObjectContext!) as! UserColour
                newUserColour.userId = user.parseObject!.objectId!
                newUserColour.colour = colour
            }
            user.colour = colour
            self.userMap[user.parseObject!.objectId!] = user
        }

    }
    
    func addColourToUser(user: User) -> User {
        //perform query to see if colour already exists
        let fetchRequest = NSFetchRequest(entityName: "UserColour")
        let predicate = NSPredicate(format: "userId == %@", user.parseObject!.objectId!)
        fetchRequest.predicate = predicate
        if let fetchResults = managedObjectContext!.executeFetchRequest(fetchRequest, error: nil) as? [UserColour] {
            println("found colour")
            if fetchResults.count > 0 {
                println("inside if statement")
                let usercolour = fetchResults[0]
                user.colour = usercolour.colour as? UIColor
            }
            else {
                println("did not find colour")
                //if not make new object
                let newUserColour = NSEntityDescription.insertNewObjectForEntityForName("UserColour", inManagedObjectContext: self.managedObjectContext!) as! UserColour
                newUserColour.userId = user.parseObject!.objectId!
                let colour = ColourGenerator.generateRandomColour()
                
                newUserColour.colour = colour
                user.colour = colour
            }
        }
        return user
        
        
    }
    
    func findPFUserFromFbid(ids: [String]) {
        let query = PFUser.query()!
        query.whereKey(parse_user_fbid, containedIn: ids)
        query.findObjectsInBackgroundWithBlock {
            (fbFriends: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let fbFriends = fbFriends as? [PFUser] {
                    FacebookManager.downloadProfilePictures(fbFriends)
                    self.addUsersToMap(fbFriends, type: UserType.FacebookFriends)
                    self.delegate?.facebookFriendsFound(fbFriends)
                }
            } else {
                print("error in GETTING PENDING USERS request")
                
            }
        }
        
    }
    
    func getFacebookFriends() {
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
                    var ids = [String]()
                    for friend in friends {
                        let id = friend.valueForKey("id") as! String
                        ids.append(id)
                        print("Id: \(id)")
                    }
                    self.findPFUserFromFbid(ids)
                }
            })
        }
    }
    
    func getFriends() {
        let query = PFRole.query()!
        query.whereKey("name", equalTo: "friendsOf_" + PFUser.currentUser()!.objectId!)
        query.orderByAscending("updatedAt")
        query.getFirstObjectInBackgroundWithBlock {
            (role: AnyObject?, error: NSError?) -> Void in
            if let role = role as? PFRole {
                let userRelation = role.relationForKey("users")
                let relationQuery = userRelation.query()!
                relationQuery.findObjectsInBackgroundWithBlock {
                    (friends: [AnyObject]?, error: NSError?) -> Void in
                    if error == nil {
                        if let friends = friends as? [PFUser] {
                            self.friends = friends
                            FacebookManager.downloadProfilePictures(friends)
                            _locationUpdater.getFriendLocationsFromServer()
                            self.addUsersToMap(friends, type: UserType.Friends)
                            self.delegate?.friendListFound(friends)
                        }
                    } else {
                        print("error searching")
                        
                    }
                }

            }
            else {
                print("Couldn't find role")
            }
        }
    }
    
    func getSentRequestList() {
        
    }
    
    func search(search: String) {
        //search for Full Name or username
        let fbQuery = PFUser.query()!
        fbQuery.whereKey("queryUsername", containsString: search)
        let uQuery = PFUser.query()!
        uQuery.whereKey("queryFullname", containsString: search)
        let query = PFQuery.orQueryWithSubqueries([fbQuery, uQuery])
        query.whereKey("objectId", notEqualTo: PFUser.currentUser()!.objectId!)
        query.findObjectsInBackgroundWithBlock {
            (searchResults: [AnyObject]?, error: NSError?) -> Void in
            if error == nil {
                if let searchResults = searchResults as? [PFUser] {
                    println("adding search users")
                    self.addUsersToMap(searchResults, type: UserType.None)
                    self.delegate?.searchFinished(searchResults)
                }
            } else {
                print("error searching")
                
            }
        }
    }
}