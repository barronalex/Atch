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
        self.friends = friends
    }
    
    override func tableViewTapped() {
        searchBar.endEditing(true)
    }
    
    override func setUpTable() {
        friendManager.getPendingRequests()
        friendManager.getFacebookFriends()
        friendManager.getFriends()
    }
    
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
        }
        else if indexPath.section == 0 || contains(pendingRequests, user) {
            cell.acceptButton.setTitle("accept", forState: .Normal)
            cell.acceptButton.tag = row
            cell.acceptButton.addTarget(self, action: "acceptButton:", forControlEvents: .TouchUpInside)
            
        }
        else {
            cell.acceptButton.setTitle("add", forState: .Normal)
            cell.acceptButton.tag = row
            cell.acceptButton.addTarget(self, action: "addButton:", forControlEvents: .TouchUpInside)
        }
        return cell

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
