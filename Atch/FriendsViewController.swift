//
//  FriendsViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/14/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse
import Bolts


class FriendsViewController: UIViewController, FriendManagerDelegate, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, UITextFieldDelegate {
    
    @IBOutlet weak var searchBar: UISearchBar!
    @IBOutlet weak var table: UITableView!
    
    var friendManager = FriendManager()
    
    var friends = [PFObject]()
    var pendingRequests = [PFObject]()
    var pendingFriends = [PFObject]()
    var facebookFriends = [PFObject]()
    
    var friendPics = [String:UIImage]()
    
    var sectionMap = [Int:[PFObject]]()
    var sectionTitles = ["", ""]
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        self.table.addGestureRecognizer(tapGesture)
        
        table.delegate = self
        table.dataSource = self
        searchBar.delegate = self
        
        
        sectionMap[0] = []
        sectionMap[1] = []
        
        friendManager.delegate = self
        
        setUpTable()
    }
    
    func tableViewTapped() {
        searchBar.endEditing(true)
    }
    
    func setUpTable() {
        friendManager.getFriends()
        friendManager.getPendingRequests()
        friendManager.getFacebookFriends()
    }

    func acceptButton(sender: AnyObject) {
        let button = sender as! UIButton
        let request = pendingRequests[button.tag]
        friendManager.acceptRequest(request)
        button.setTitle("friends", forState: .Normal)
    }
    
    func addButton(sender: AnyObject) {
        let button = sender as! UIButton
        let friend = sectionMap[1]![button.tag]
        print("Requested: \(friend.objectId)")
        friendManager.sendRequest(friend.objectId!)
        button.setTitle("sent", forState: .Normal)
    }
    
    @IBAction func mapPressed() {
        //if friends.count != 0 {
            self.performSegueWithIdentifier("friendstomap", sender: nil)
        //}
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "friendstomap" {
            //let destVC = segue.destinationViewController as! AtchMapViewController
            //destVC.friends = friends
        }
        
    }
    
    func reset() {
        print("cancelllllleedd")
        self.view.endEditing(true)
        setUpTable()
    }

}

//Table View Methods
extension FriendsViewController {
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        return setUpCell(tableView, indexPath: indexPath)
    }
    
    func setUpCell(tableView: UITableView, indexPath: NSIndexPath) -> PendingFriendEntry {
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
        if indexPath.section == 0 {
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
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sectionMap[section]!.count
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return sectionMap.count
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

//FriendManager methods
extension FriendsViewController {
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("triggered in Friends")
        var dataMap = notification.userInfo as! [String:[String:UIImage]]
        friendPics += dataMap["images"]!
        table.reloadData()
        
    }
    
    func friendListFound(friends: [PFUser]) {
        print("friends found")
        self.friends = friends
        FacebookManager.downloadProfilePictures(friends)
    }
    
    func facebookFriendsFound(facebookFriends: [PFUser]) {
        print("facebook friends acquired")
        self.facebookFriends = facebookFriends
        if facebookFriends.count > 0 {
            sectionTitles[1] = "Facebook Friends"
            sectionMap[1] = facebookFriends
            FacebookManager.downloadProfilePictures(facebookFriends)
            table.reloadData()
        }
    }
    
    func pendingRequestsFound(requests: [PFObject], users: [PFUser]) {
        //present requests
        print("requests found")
        pendingRequests = requests
        pendingFriends = users
        if pendingFriends.count > 0 {
            sectionTitles[0] = "Pending Requests"
            sectionMap[0] = pendingFriends
            FacebookManager.downloadProfilePictures(users)
            table.reloadData()
        }
    }
    
    func friendRequestSent() {
        
    }
    
    func friendRequestAccepted() {
        
    }
    
    //    func removeDuplicatePicUsers(users: [PFObject]) -> [PFObject] {
    //        var nonDupFriends = users
    //        for var i = 0; i < users.count; i++ {
    //            if friendPics[users[i].objectId!] == nil {
    //                nonDupFriends.removeAtIndex(i)
    //            }
    //        }
    //        return nonDupFriends
    //    }

}
    
