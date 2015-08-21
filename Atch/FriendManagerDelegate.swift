//
//  FriendManagerDelegate.swift
//  Atch
//
//  Created by Alex Barron on 8/14/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse

protocol FriendManagerDelegate {
    
    func friendRequestSent()
    
    func friendRequestAccepted()
    
    func friendListFound(friends: [PFUser])
    
    func pendingRequestsFound(requests: [PFObject], users: [PFUser])
    
    func facebookFriendsFound(facebookFriends: [PFUser])
    
    func searchFinished(searchResults: [PFUser])
}