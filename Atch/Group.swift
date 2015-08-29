//
//  Group.swift
//  Atch
//
//  Created by Alex Barron on 8/29/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps

class Group {
    
    var toUsers = [String]()
    var position: CLLocation?
    var marker: GMSMarker?
    
    init(toUsers: [String], position: CLLocation) {
        self.toUsers = toUsers
        self.position = position
    }
    
}