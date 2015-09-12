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
    
    var actualGroups = [Group]()
    var onlineFriends = [PFObject]()
    var offlineFriends = [PFObject]()
    var sectionMap = [Int:[PFObject]]()
    var sectionTitles = ["", "", ""]
    var userToRequestMap = [String:PFObject]()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("groupsReceived"), name: groupsFoundNotificationKey, object: nil)
        
        table.delegate = self
        table.dataSource = self
        
        if _friendManager.groups.count > 0 {
            println("count: \(_friendManager.groups.count)")
            findActualGroups()
            if actualGroups.count > 0 {
                sectionTitles[0] = "Groups"
            }
            table.reloadData()
        }
        if _friendManager.friends.count > 0 {
            
            //split friends into online and offline
            separateOfflineFriends()
            if onlineFriends.count > 0 {
                sectionTitles[1] = "Online Friends"
            }
            if offlineFriends.count > 0 {
                sectionTitles[2] = "Offline Friends"
            }
            
        }
        
        _friendManager.delegate = self
        setUpTable()
    }
    
    func separateOfflineFriends() {
        for friend in _friendManager.friends {
            if let online = _friendManager.userMap[friend.objectId!]?.online {
                if online {
                    onlineFriends.append(friend)
                }
                else {
                    offlineFriends.append(friend)
                }
            }
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "friendstomap" {
            let destVC = segue.destinationViewController as! AtchMapViewController
            destVC.firstLocation = false
        }
    }
    
    func tableViewTapped() {
        
    }
    
    func imageTapped(sender: AnyObject) {
        println("imageTapped")
        if let recognizer = sender as? UIGestureRecognizer {
            println("down a level")
            let row = recognizer.view!.tag
            var user: PFObject
            if row < 0 {
                println("doing an offline friend")
                user = offlineFriends[-row - 1]
            }
            else {
                user = onlineFriends[row]
            }
                println("down another level")
                //change colour of given user
            println("userIdOfClickedFriend: \(user.objectId!)")
            if let fulluser = _friendManager.userMap[user.objectId!] {
                _friendManager.changeUserColour(fulluser)
            }
            _locationUpdater.getFriendLocationsFromServer()
            if _friendManager.userMap[user.objectId!]?.group != nil {
                _friendManager.userMap[user.objectId!]?.group?.image = ImageProcessor.createImageFromGroup(_friendManager.userMap[user.objectId!]!.group!)
            }
            
            table.reloadData()
        }
        
    }
    
    func setUpTable() {
        if _friendManager.friends.count == 0 {
            _friendManager.getFriends()
        }
        else {
            table.reloadData()
            if !_friendManager.downloadedPics {
                FacebookManager.downloadProfilePictures(_friendManager.friends)
            }
        }
    }
    
    func reset() {
        print("cancelllllleedd")
        setUpTable()
    }
    
    func goToChat(sender: AnyObject) {
        if let button = sender as? UIButton {
            let row = button.tag
            if row < 0 {
                goToMap(offlineFriends[-row - 1].objectId!, toMessages: true)
            }
            else {
                goToMap(onlineFriends[row].objectId!, toMessages: true)
            }
            
        }
    }
    
    func goToChatFromGroup(sender: AnyObject) {
        println("here")
        if let button = sender as? UIButton {
            let row = button.tag
            goToMapFromGroup(row, toMessages: true)
        }
    }
    
    func goToMap(friendId: String, toMessages: Bool) {
        //go to friends messaging screen
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let atchVC = storyboard.instantiateViewControllerWithIdentifier("AtchMapViewController") as! AtchMapViewController
        self.showViewController(atchVC, sender: nil)
        atchVC.firstLocation = false
        atchVC.tappedUserIds = [friendId]
        if !toMessages {
            atchVC.putBannerUp()
        }
        if let friendLocation = _friendManager.userMap[friendId]?.marker?.position {
            println("animating")
            _mapView?.animateToCameraPosition(GMSCameraPosition(target: friendLocation, zoom: closeZoomLevel, bearing: 0, viewingAngle: 0))
        }
        if toMessages {
            atchVC.bringUpMessagesScreen()
        }
    }
    
    func goToMapFromGroup(row: Int, toMessages: Bool) {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let atchVC = storyboard.instantiateViewControllerWithIdentifier("AtchMapViewController") as! AtchMapViewController
        self.showViewController(atchVC, sender: nil)
        atchVC.firstLocation = false
        
        let group = actualGroups[row]
        println("toUsers: \(group.toUsers)")
        atchVC.tappedUserIds = group.toUsers
        if !toMessages {
            atchVC.putBannerUp()
        }
        if let friendLocation = group.position?.coordinate {
            println("animating")
            _mapView?.animateToCameraPosition(GMSCameraPosition(target: friendLocation, zoom: closeZoomLevel, bearing: 0, viewingAngle: 0))
        }
        if toMessages {
            atchVC.bringUpMessagesScreen()
        }

    }


}

//#MARK: Table View Methods
extension FriendsViewController {
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 0 {
             goToMapFromGroup(indexPath.row, toMessages: false)
        }
        else if indexPath.section == 1 {
            let friend = onlineFriends[indexPath.row].objectId!
            goToMap(friend, toMessages: false)
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return sectionTitles[section]
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return setUpGroupCell(tableView, indexPath: indexPath)
        }
        else if indexPath.section == 1{
            return setUpFriendCell(tableView, indexPath: indexPath, online: true)
        }
        else {
            return setUpFriendCell(tableView, indexPath: indexPath, online: false)
        }
    }
    
    func setUpGroupCell(tableView: UITableView, indexPath: NSIndexPath) -> FriendEntry {
        print("row: \(indexPath.row)")
        let cell = tableView.dequeueReusableCellWithIdentifier("group") as! GroupEntry
        cell.userInteractionEnabled = true
        var sectionArr = self.actualGroups
        let row = indexPath.row
        let group = sectionArr[row]
        var groupName = ""
        for user in group.toUsers {
            if let name = _friendManager.userMap[user]?.parseObject?.objectForKey("firstname") as? String {
                groupName = groupName + name + ", "
            }
        }
        if count(groupName) > 1 {
            groupName = groupName.substringToIndex(groupName.endIndex.predecessor().predecessor())

        }
        cell.name.text = groupName
        cell.acceptButton.setImage(ImageProcessor.getColourMessageBubble(UIColor.blackColor()), forState: .Normal)
        cell.acceptButton.showsTouchWhenHighlighted = true
        cell.acceptButton.tag = row
        cell.acceptButton.addTarget(self, action: Selector("goToChatFromGroup:"), forControlEvents: .TouchUpInside)

        if let image = group.image {
            //let colour = _friendManager.userMap[group.toUsers[0]]?.colour
            cell.profileImage.image = image
        }
        else {
            cell.profileImage.image = nil
        }
        return cell
    }
    
    func setUpFriendCell(tableView: UITableView, indexPath: NSIndexPath, online: Bool) -> FriendEntry {
        print("row: \(indexPath.row)")
        var cell = tableView.dequeueReusableCellWithIdentifier("potentialFriend") as! FriendEntry
        cell.userInteractionEnabled = true
        var sectionArr = [PFObject]()
        if online {
            sectionArr = onlineFriends
        }
        else {
            sectionArr = offlineFriends
        }
        let row = indexPath.row
        let user = sectionArr[row]
        if let username = user.objectForKey(parse_user_username) as? String {
            print("table doin: \(username)")
            cell.username.text = username
        }
        if let fullname = user.objectForKey(parse_user_fullname) as? String {
            cell.name.text = fullname
        }
        let fulluser = _friendManager.userMap[user.objectId!]
        if !fulluser!.online {
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.name.textColor = UIColor.redColor()
        }
        setUpFriendProfileImage(fulluser, cell: &cell, row: row, online: online)
        if let colour = fulluser?.colour {
            cell.acceptButton.setImage(ImageProcessor.getColourMessageBubble(colour), forState: .Normal)
            cell.acceptButton.showsTouchWhenHighlighted = true
        }
        if online {
            cell.acceptButton.tag = row
        }
        else {
            cell.acceptButton.tag = -row - 1
        }
        cell.acceptButton.addTarget(self, action: Selector("goToChat:"), forControlEvents: .TouchUpInside)
        
        
        return cell
    }
    
    func setUpFriendProfileImage(fulluser: User?, inout cell: FriendEntry, row: Int, online: Bool) {
        if let image = fulluser?.image {
            if let colour = fulluser?.colour {
                cell.profileImage.image = ImageProcessor.createCircle(image, borderColour: colour, markerSize: false)
            }
        }
        else {
            cell.profileImage.image = nil
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("imageTapped:"))
        if online {
            cell.profileImage.tag = row
        }
        else {
            cell.profileImage.tag = -row - 1
        }
        cell.profileImage.addGestureRecognizer(tapGesture)
        cell.profileImage.userInteractionEnabled = true
        cell.acceptButton.userInteractionEnabled = true
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.actualGroups.count
        }
        else if section == 1 {
            return self.onlineFriends.count
        }
        else {
            return self.offlineFriends.count
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        if indexPath.section == 0 {
            return nil
        }
        let row = indexPath.row
        let user = _friendManager.friends[row]
        let delete = UITableViewRowAction(style: .Normal, title: "delete") { action, index in
            println("delete friend")
            PFCloud.callFunctionInBackground("deleteFriend", withParameters: ["friendId":user.objectId!])
            self.table.editing = false
            _friendManager.friends.removeAtIndex(row)
            self.table.reloadData()
            let cell = tableView.cellForRowAtIndexPath(indexPath) as! FriendEntry
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

//#MARK: FriendManager methods
extension FriendsViewController {
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("triggered in Friends")
        table.reloadData()
        
    }
    
    func friendListFound(friends: [PFUser]) {
        print("friends found")
        sectionTitles[1] = "Friends"
        sectionMap[1] = friends
        separateOfflineFriends()
        table.reloadData()
    }
    
    func facebookFriendsFound(facebookFriends: [PFUser]) {
        print("facebook friends acquired")
        if facebookFriends.count > 0 {
            sectionTitles[1] = "Facebook Friends"
            sectionMap[1] = facebookFriends
            
            table.reloadData()
        }
    }
    
    func pendingToRequestsFound(requests: [PFObject], users: [PFUser]) {
        //present requests
        for var i = 0; i < users.count; i++ {
            userToRequestMap[users[i].objectId!] = requests[i]
        }
        print("requests found")
        if users.count > 0 {
            sectionTitles[0] = "Pending Requests"
            sectionMap[0] = users
            
            table.reloadData()
        }
    }
    
    func pendingFromRequestsFound(requests: [PFObject], users: [PFUser]) {
        //present requests
        for var i = 0; i < users.count; i++ {
            userToRequestMap[users[i].objectId!] = requests[i]
        }
        print("from requests found")
        table.reloadData()
    }
    
    func groupsReceived() {
        println("groups received")
        findActualGroups()
        if self.actualGroups.count > 0 {
            sectionTitles[0] = "Groups"
        }
        else {
            sectionTitles[0] = ""
        }
        table.reloadData()
    }
    
    func findActualGroups() {
        var groups = [Group]()
        for var i = 0; i < _friendManager.groups.count; i++ {
            println("group members: \(_friendManager.groups[i].toUsers)")
            if _friendManager.groups[i].toUsers.count > 1 {
                groups.append(_friendManager.groups[i])            }
        }
        self.actualGroups = groups
    }
    
    func friendRequestSent(req: PFObject, userId: String) {
        println("friend request sent")
        self.userToRequestMap[userId] = req
    }
    
    func friendRequestAccepted() {
        
    }

}
    
