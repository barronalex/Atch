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
        searchBar.delegate = self
    }
    
    override func friendListFound(friends: [PFUser]) {
        println("friend list found")
        self.friends = friends
        table.reloadData()
    }
    
    override func tableViewTapped() {
        searchBar.endEditing(true)
    }
    
    override func setUpTable() {
        friendManager.getPendingRequests(true)
        friendManager.getPendingRequests(false)
        friendManager.getFacebookFriends()
        if self.friends.count == 0 {
            friendManager.getFriends()
        }
        
    }
    
}

//table view methods
extension AddFriendsViewController {
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        print("row: \(indexPath.row)")
        let cell = tableView.dequeueReusableCellWithIdentifier("potentialFriend") as! PendingFriendEntry
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if let username = user.objectForKey("username") as? String {
            print("table doin: \(username)")
            cell.username.text = username
        }
        if let fullname = user.objectForKey("fullname") as? String {
            cell.name.text = fullname
        }
        if let image = friendPics[user.objectId!] {
            cell.profileImage.image = ImageProcessor.createCircle(image)
        }
        else {
            cell.profileImage.image = nil
        }
        //show tick if already friends
        if contains(friends, user) {
            cell.acceptButton.setTitle("√", forState: .Normal)
            cell.acceptButton.userInteractionEnabled = false
        }
        else if contains(pendingFriendsFromUser, user) {
            cell.acceptButton.setTitle("request sent", forState: .Normal)
            cell.acceptButton.userInteractionEnabled = false
        }
        else if indexPath.section == 0 || contains(pendingRequestsToUser, user) {
            cell.acceptButton.setTitle("accept", forState: .Normal)
            cell.acceptButton.tag = row
            cell.acceptButton.addTarget(self, action: "acceptButton:", forControlEvents: .TouchUpInside)
            
        }
        else {
            cell.acceptButton.setTitle("add", forState: .Normal)
            println("ADDING")
            cell.acceptButton.userInteractionEnabled = true
            cell.acceptButton.tag = row
            cell.acceptButton.addTarget(self, action: "addButton:", forControlEvents: .TouchUpInside)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if contains(pendingFriendsFromUser, user) {
            let cancel = UITableViewRowAction(style: .Normal, title: "cancel request") { action, index in
                println("request cancelled")
                let reqIndex = find(self.pendingFriendsFromUser, user)!
                let friendRequest = self.pendingRequestsFromUser[reqIndex]
                PFCloud.callFunctionInBackground("cancelFriendRequest", withParameters: ["friendRequestId":friendRequest.objectId!])
                
            }
            cancel.backgroundColor = UIColor.redColor()
            return [cancel]
        }
        if contains(pendingFriendsToUser, user) {
            let reject = UITableViewRowAction(style: .Normal, title: "reject") { action, index in
                println("request rejected")
                let reqIndex = find(self.pendingFriendsFromUser, user)!
                let friendRequest = self.pendingRequestsFromUser[reqIndex]
                friendRequest.setObject("rejected", forKey: "state")
                friendRequest.saveInBackground()
            }
            reject.backgroundColor = UIColor.redColor()
            return [reject]

        }
        
        let delete = UITableViewRowAction(style: .Normal, title: "delete") { action, index in
            println("delete friend")
            PFCloud.callFunctionInBackground("deleteFriend", withParameters: ["friendId":user.objectId!])
        }
        delete.backgroundColor = UIColor.redColor()
        return [delete]
    }
    
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        var sectionArr = sectionMap[indexPath.section]!
        let row = indexPath.row
        let user = sectionArr[row]
        if contains(pendingFriendsFromUser, user) || contains(pendingFriendsToUser, user) || contains(friends, user) {
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
            friendManager.search(searchBar.text!)
        }
    }
    
    
}
