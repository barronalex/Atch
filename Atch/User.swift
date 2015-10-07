//
//  User.swift
//  Atch
//
//  Created by Alex Barron on 8/28/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse
import GoogleMaps
import CoreLocation

enum UserType: Int {
    case Friends = 1, PendingTo, PendingFrom, FacebookFriends, None, Me
}

class User {
    
    var type = UserType.None
    
    var colour: UIColor?
    
    var marker: GMSMarker?
    
    var location: CLLocation?
    
    var parseObject: PFObject?
    
    var group: Group?
    
    var image: UIImage?
    
    var online = true
    
    init(type: UserType, parseObject: PFObject) {
        self.type = type
        self.parseObject = parseObject
    }
    
}