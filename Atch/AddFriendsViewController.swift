//
//  AddFriendsViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/23/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import Parse

class AddFriendsViewController: FriendsViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    override func viewDidLoad() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        
        table.delegate = self
        table.dataSource = self
        print("LOADED")
        searchBar.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        self.table.addGestureRecognizer(tapGesture)
        _friendManager.delegate = self
        sectionMap[0] = _friendManager.pendingFriendsTo
        sectionMap[1] = _friendManager.facebookFriends
        setUpTable()
    }
    
    override func friendListFound(friends: [PFUser]) {
        print("friend list found")
        dispatch_async(dispatch_get_main_queue(), {
            self.table.reloadData()
        })
    }
    
    override func tableViewTapped() {
        searchBar.endEditing(true)
    }
    
    override func setUpTable() {
        
        if _friendManager.pendingFriendsFrom.count == 0 {
            _friendManager.getPendingRequests(true)
        }
        if _friendManager.pendingFriendsTo.count == 0 {
            _friendManager.getPendingRequests(false)
        }
        else {
            sectionTitles[0] = "Pending Requests"
        }
        if _friendManager.facebookFriends.count == 0 {
            _friendManager.getFacebookFriends()
        }
        else {
            sectionTitles[1] = "Facebook Friends"
        }
        if _friendManager.friends.count == 0 {
            _friendManager.getFriends()
        }
        sectionMap[0] = _friendManager.pendingFriendsTo
        sectionMap[1] = _friendManager.facebookFriends
        table.reloadData()
    }
    
    func acceptButton(sender: AnyObject) {
        let button = sender as! UIButton
        if sectionTitles[1] == "Search Results" {
            let user = sectionMap[1]![button.tag]
            if let request = userToRequestMap[user.objectId!] {
                _friendManager.acceptRequest(request)
                //update usermap to show that these people are friends
                let friend = _friendManager.userMap[user.objectId!]!
                friend.type = UserType.Friends
                _friendManager.userMap[user.objectId!]! = friend
            }
        }
        else {
            let user = sectionMap[0]![button.tag]
            if let request = userToRequestMap[user.objectId!] {
                _friendManager.acceptRequest(request)
                let friend = _friendManager.userMap[user.objectId!]!
                friend.type = UserType.Friends
                _friendManager.userMap[user.objectId!]! = friend
            }
        }
        table.reloadData()
    }
    
    func addButton(sender: AnyObject) {
        let button = sender as! UIButton
        let friend = sectionMap[1]![button.tag]
        print("here")
        button.hidden = true
        button.userInteractionEnabled = false
        if let cell = table.cellForRowAtIndexPath(NSIndexPath(forRow: button.tag, inSection: 1)) as? PendingFriendEntry {
            print("row: \(button.tag)")
            print("here")
            cell.acceptButton.hidden = false
            cell.acceptButton.setImage(UIImage(named: "Sent-100.png"), forState: .Normal)
            //set flag in map to pending from user
            let user = _friendManager.userMap[friend.objectId!]!
            user.type = UserType.PendingFrom
            _friendManager.userMap[friend.objectId!] = user

            table.reloadData()
        }
        print("Requested: \(friend.objectId)")
        _friendManager.sendRequest(friend.objectId!)
    }
    
    func addButtonRequest(sender: AnyObject) {
        let button = sender as! UIButton
        let friend: PFObject
        if sectionTitles[1] == "Search Results" {
            friend = sectionMap[1]![button.tag]
        }
        else {
            friend = sectionMap[0]![button.tag]
        }
        print("request add")
        button.hidden = true
        button.userInteractionEnabled = false
        if let cell = table.cellForRowAtIndexPath(NSIndexPath(forRow: button.tag, inSection: 1)) as? PendingFriendEntry {
            print("row: \(button.tag)")
            print("here")
            cell.acceptButton.hidden = false
            cell.acceptButton.setImage(UIImage(named: "Ok-512.png"), forState: .Normal)
            //set flag in map to pending from user
            let user = _friendManager.userMap[friend.objectId!]!
            user.type = UserType.Friends
            _friendManager.userMap[friend.objectId!] = user
            _friendManager.getPendingRequests(false)
            _friendManager.getFriends()
            table.reloadData()
        }
        print("Requested: \(friend.objectId)")
        _friendManager.acceptRequest(friend.objectId!)
    }
}

//#MARK: Table view methods
extension AddFriendsViewController {
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("row: \(indexPath.row)")
        let cell = tableView.dequeueReusableCellWithIdentifier("potentialFriend") as! PendingFriendEntry
        cell.addButton.hidden = true
        cell.acceptButton.hidden = false
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if let username = user.objectForKey(parse_user_username) as? String {
            print("table doin: \(username)")
            cell.username.text = username
        }
        if let fullname = user.objectForKey(parse_user_fullname) as? String {
            cell.name.text = fullname
        }
        if let image = _friendManager.userMap[user.objectId!]?.image {
            let colour = _friendManager.userMap[user.objectId!]?.colour
            cell.profileImage.image = ImageProcessor.createCircle(image, borderColour: colour!, markerSize: false)
        }
        else {
            //get the image from facebook
            cell.profileImage.image = nil
        }
        if let fulluser = _friendManager.userMap[user.objectId!] {
            //show tick if already friends
            if fulluser.type == UserType.Friends {
                cell.acceptButton.setImage(UIImage(named: "Ok-512.png"), forState: .Normal)
                cell.acceptButton.setTitle("", forState: .Normal)
                cell.acceptButton.userInteractionEnabled = false
            }
            else if fulluser.type == UserType.PendingFrom {
                cell.acceptButton.setImage(UIImage(named: "Sent-100.png"), forState: .Normal)
                cell.acceptButton.userInteractionEnabled = false
            }
            else if fulluser.type == UserType.PendingTo {
                print("pending to!")
                cell.addButton.hidden = false
                cell.addButton.userInteractionEnabled = true
                cell.acceptButton.hidden = true
                cell.addButton.tag = row
                cell.addButton.addTarget(self, action: "addButtonRequest:", forControlEvents: .TouchUpInside)
            }
            else {
                cell.addButton.hidden = false
                cell.addButton.userInteractionEnabled = true
                cell.acceptButton.hidden = true
                cell.addButton.tag = row
                cell.addButton.addTarget(self, action: "addButton:", forControlEvents: .TouchUpInside)
            }
            return cell
        }
        return UITableViewCell()
        
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        let fulluser = _friendManager.userMap[user.objectId!]!
        if fulluser.type == UserType.PendingFrom {
            let cancel = UITableViewRowAction(style: .Normal, title: "cancel") { action, index in
                
                if let friendRequest = self.userToRequestMap[user.objectId!] {
                    print("request cancelled")
                    PFCloud.callFunctionInBackground("cancelFriendRequest", withParameters: ["friendRequestId":friendRequest.objectId!])
                    fulluser.type = UserType.None
                    _friendManager.userMap[user.objectId!] = fulluser
                    self.table.editing = false
                    let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
                    cell.acceptButton.userInteractionEnabled = false
                    self.table.reloadData()
                }
                
                
            }
            cancel.backgroundColor = UIColor.redColor()
            return [cancel]
        }
        if fulluser.type == UserType.PendingTo {
            let reject = UITableViewRowAction(style: .Normal, title: "reject") { action, index in
                print("request rejected")
                if let friendRequest = self.userToRequestMap[user.objectId!] {
                    friendRequest.setObject("rejected", forKey: parse_friendRequest_state)
                    friendRequest.saveInBackground()
                    self.table.editing = false
                    let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
                    cell.acceptButton.setImage(UIImage(named: "Cancel 2-100.png"), forState: .Normal)
                    cell.acceptButton.userInteractionEnabled = false
                    fulluser.type = UserType.None
                    _friendManager.userMap[user.objectId!] = fulluser
                    self.table.reloadData()
                    
                }
            }
            reject.backgroundColor = UIColor.redColor()
            return [reject]
            
        }
        
        let delete = UITableViewRowAction(style: .Normal, title: "delete") { action, index in
            
            PFCloud.callFunctionInBackground("deleteFriend", withParameters: ["friendId":user.objectId!]) {
                (response) in
                print("deleting friend")
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
                cell.acceptButton.setImage(UIImage(named: "Cancel 2-100.png"), forState: .Normal)
                cell.acceptButton.userInteractionEnabled = false
                _friendManager.userMap.removeValueForKey(user.objectId!)
                _friendManager.getFriends()
            }
            self.table.editing = false
            
        }
        delete.backgroundColor = UIColor.redColor()
        return [delete]
    }
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if let fulluser = _friendManager.userMap[user.objectId!] {
            if fulluser.type == UserType.PendingFrom || fulluser.type == UserType.PendingTo || fulluser.type == UserType.Friends {
                return true
            }
        }
        return false
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionMap[section]!.count
    }
    
    func reset() {
        print("cancelllllleedd")
        setUpTable()
    }
    
}

//#MARK: SearchBar methods
extension AddFriendsViewController {
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        print("cancelled")
    }
    
    override func searchFinished(searchResults: [PFUser]) {
        print("search finished")
        sectionTitles[0] = ""
        sectionTitles[1] = "Search Results"
        sectionMap[0] = []
        sectionMap[1] = searchResults
        FacebookManager.downloadProfilePictures(searchResults)
        table.reloadData()
    }
    
    func searchBar(searchBar: UISearchBar, textDidChange searchText: String) {
        print("search: \(searchText)")
        if searchText == "" {
            reset()
        }
        else {
            _friendManager.search(searchBar.text!)
        }
    }
    
    
}
