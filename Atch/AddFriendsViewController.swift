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
        super.viewDidLoad()
        println("LOADED")
        searchBar.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        self.table.addGestureRecognizer(tapGesture)
    }
    
    override func friendListFound(friends: [PFUser]) {
        println("friend list found")
        table.reloadData()
    }
    
    override func tableViewTapped() {
        searchBar.endEditing(true)
    }
    
    override func setUpTable() {
        _friendManager.getPendingRequests(true)
        _friendManager.getPendingRequests(false)
        _friendManager.getFacebookFriends()
        if _friendManager.friends.count == 0 {
            _friendManager.getFriends()
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
        println("here")
        button.hidden = true
        button.userInteractionEnabled = false
        if let cell = table.cellForRowAtIndexPath(NSIndexPath(forRow: button.tag, inSection: 1)) as? PendingFriendEntry {
            println("row: \(button.tag)")
            println("here")
            cell.acceptButton.hidden = false
            cell.acceptButton.setImage(UIImage(named: "Sent-100.png"), forState: .Normal)
            _friendManager.pendingFriendsFromUser.append(friend)
            table.reloadData()
        }
        print("Requested: \(friend.objectId)")
        _friendManager.sendRequest(friend.objectId!)
    }
}

//table view methods
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
        if let image = _friendManager.friendPics[user.objectId!] {
            cell.profileImage.image = ImageProcessor.createCircle(image)
        }
        else {
            cell.profileImage.image = nil
        }
        //show tick if already friends
        if contains(_friendManager.friends, user) {
            cell.acceptButton.setImage(UIImage(named: "Ok-512.png"), forState: .Normal)
            cell.acceptButton.setTitle("", forState: .Normal)
            cell.acceptButton.userInteractionEnabled = false
        }
        else if contains(_friendManager.pendingFriendsFromUser, user) {
            cell.acceptButton.setImage(UIImage(named: "Sent-100.png"), forState: .Normal)
            cell.acceptButton.userInteractionEnabled = false
        }
        else if indexPath.section == 0 || contains(_friendManager.pendingRequestsToUser, user) {
            cell.acceptButton.userInteractionEnabled = true
            cell.acceptButton.setTitle("accept", forState: .Normal)
            cell.acceptButton.tag = row
            cell.acceptButton.addTarget(self, action: "acceptButton:", forControlEvents: .TouchUpInside)
            
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
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if contains(_friendManager.pendingFriendsFromUser, user) {
            let cancel = UITableViewRowAction(style: .Normal, title: "cancel") { action, index in
                println("request cancelled")
                let reqIndex = find(_friendManager.pendingFriendsFromUser, user)!
                let friendRequest = _friendManager.pendingRequestsFromUser[reqIndex]
                PFCloud.callFunctionInBackground("cancelFriendRequest", withParameters: ["friendRequestId":friendRequest.objectId!]) {
                    (response) in
                    dispatch_async(dispatch_get_main_queue()) {
                        _friendManager.getPendingRequests(true)
                    }
                }
                self.table.editing = false
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
                cell.acceptButton.userInteractionEnabled = false
                
            }
            cancel.backgroundColor = UIColor.redColor()
            return [cancel]
        }
        if contains(_friendManager.pendingFriendsToUser, user) {
            let reject = UITableViewRowAction(style: .Normal, title: "reject") { action, index in
                println("request rejected")
                let reqIndex = find(_friendManager.pendingFriendsFromUser, user)!
                let friendRequest = _friendManager.pendingRequestsFromUser[reqIndex]
                friendRequest.setObject("rejected", forKey: parse_friendRequest_state)
                friendRequest.saveInBackground()
                self.table.editing = false
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
                cell.acceptButton.setImage(UIImage(named: "Cancel 2-100.png"), forState: .Normal)
                _friendManager.pendingFriendsToUser.removeAtIndex(reqIndex)
                cell.acceptButton.userInteractionEnabled = false
            }
            reject.backgroundColor = UIColor.redColor()
            return [reject]

        }
        
        let delete = UITableViewRowAction(style: .Normal, title: "delete") { action, index in
            println("delete friend")
            PFCloud.callFunctionInBackground("deleteFriend", withParameters: ["friendId":user.objectId!]) {
                (response) in
                let cell = tableView.cellForRowAtIndexPath(indexPath) as! PendingFriendEntry
                cell.acceptButton.setImage(UIImage(named: "Cancel 2-100.png"), forState: .Normal)
                cell.acceptButton.userInteractionEnabled = false
                _friendManager.getFriends()
            }
            self.table.editing = false

        }
        delete.backgroundColor = UIColor.redColor()
        return [delete]
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if contains(_friendManager.pendingFriendsFromUser, user) || contains(_friendManager.pendingFriendsToUser, user) || contains(_friendManager.friends, user) {
            return true
        }
        return false
    }
}

//SearchBar methods
extension FriendsViewController {
    
    func searchBarCancelButtonClicked(searchBar: UISearchBar) {
        println("cancelled")
    }
    
    func searchFinished(searchResults: [PFUser]) {
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
            self.reset()
        }
        else {
            _friendManager.search(searchBar.text!)
        }
    }
    
    
}
