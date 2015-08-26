//
//  FriendsViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/14/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse
import Bolts
import GoogleMaps


class FriendsViewController: UIViewController, FriendManagerDelegate, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate {
    
    
    @IBOutlet weak var table: UITableView!
    
    var sectionMap = [Int:[PFObject]]()
    var sectionTitles = ["", ""]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        
        table.delegate = self
        table.dataSource = self
        
        sectionMap[0] = []
        sectionMap[1] = []
        
        _friendManager.delegate = self
        setUpTable()
    }
    
    func tableViewTapped() {
        
    }
    
    func setUpTable() {
        if _friendManager.friends.count == 0 {
            _friendManager.getFriends()
        }
        else {
            sectionMap[0] = _friendManager.friends
            table.reloadData()
            if _friendManager.friendPics.count == 0 {
                FacebookManager.downloadProfilePictures(_friendManager.friends)
            }
        }
    }

    func acceptButton(sender: AnyObject) {
        let button = sender as! UIButton
        let request = _friendManager.pendingRequestsToUser[button.tag]
        _friendManager.acceptRequest(request)
        button.setTitle("friends", forState: .Normal)
    }
    
    func addButton(sender: AnyObject) {
        let button = sender as! UIButton
        let friend = sectionMap[1]![button.tag]
        print("Requested: \(friend.objectId)")
        _friendManager.sendRequest(friend.objectId!)
        button.setTitle("sent", forState: .Normal)
        button.userInteractionEnabled = false
    }
    
    func reset() {
        print("cancelllllleedd")
        self.view.endEditing(true)
        setUpTable()
    }

}

//Table View Methods
extension FriendsViewController {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        //go to friends messaging screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let atchVC = storyboard.instantiateViewControllerWithIdentifier("AtchMapViewController") as! AtchMapViewController
        self.showViewController(atchVC, sender: nil)
        let friendId = _friendManager.friends[indexPath.row].objectId!
        var toUsers = [PFUser.currentUser()!.objectId!, friendId]
        if let friendLocation = _friendManager.userMarkers[friendId]?.position {
            println("animating")
            atchVC.mapView!.animateToLocation(friendLocation)
        }
        atchVC.tappedUserId = friendId
        atchVC.containerVC?.goToMessages(toUsers)
        atchVC.bringUpMessagesScreen()
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return setUpCell(tableView, indexPath: indexPath)
    }
    
    func setUpCell(tableView: UITableView, indexPath: NSIndexPath) -> PendingFriendEntry {
        print("row: \(indexPath.row)")
        let cell = tableView.dequeueReusableCellWithIdentifier("potentialFriend") as! PendingFriendEntry
        cell.userInteractionEnabled = true
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if let username = user.objectForKey(parse_user_username) as? String {
            print("table doin: \(username)")
            cell.username.text = username
        }
        cell.acceptButton.hidden = true
        if let fullname = user.objectForKey(parse_user_fullname) as? String {
            cell.name.text = fullname
        }
        if let image = _friendManager.friendPics[user.objectId!] {
            cell.profileImage.image = ImageProcessor.createCircle(image)
        }
        else {
            cell.profileImage.image = nil
        }
        return cell
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionMap[section]!.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionMap.count
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        let delete = UITableViewRowAction(style: .Normal, title: "delete") { action, index in
            println("delete friend")
            PFCloud.callFunctionInBackground("deleteFriend", withParameters: ["friendId":user.objectId!])
            self.table.editing = false
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
            cell.acceptButton.setTitle("deleted", forState: .Normal)
        }
        delete.backgroundColor = UIColor.redColor()
        
        return [delete]
    }
    
    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
}

//FriendManager methods
extension FriendsViewController {
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("triggered in Friends")
        table.reloadData()
        
    }
    
    func friendListFound(friends: [PFUser]) {
        print("friends found")
        sectionMap[0] = friends
        table.reloadData()
        FacebookManager.downloadProfilePictures(friends)
    }
    
    func facebookFriendsFound(facebookFriends: [PFUser]) {
        print("facebook friends acquired")
        if facebookFriends.count > 0 {
            sectionTitles[1] = "Facebook Friends"
            sectionMap[1] = facebookFriends
            FacebookManager.downloadProfilePictures(facebookFriends)
            table.reloadData()
        }
    }
    
    func pendingToRequestsFound(requests: [PFObject], users: [PFUser]) {
        //present requests
        print("requests found")
        if _friendManager.pendingFriendsToUser.count > 0 {
            sectionTitles[0] = "Pending Requests"
            sectionMap[0] = _friendManager.pendingFriendsToUser
            FacebookManager.downloadProfilePictures(users)
            table.reloadData()
        }
    }
    
    func pendingFromRequestsFound(requests: [PFObject], users: [PFUser]) {
        //present requests
        print("from requests found")
    }
    
    func friendRequestSent() {

    }
    
    func friendRequestAccepted() {
        
    }

}
    
