//
//  UserColourMap.swift
//  Atch
//
//  Created by Alex Barron on 8/28/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreData

class UserColour: NSManagedObject {

    @NSManaged var userId: String
    @NSManaged var colour: AnyObject

}
