//
//  User.swift
//  Atch
//
//  Created by Alex Barron on 8/28/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse

enum UserType {
    case Friends
    case FacebookFriends
    case PendingFrom
    case PendingTo
    case None
}

class User: PFUser {
    
    var type = UserType.None
    
    var colour: UIColor?
    
}