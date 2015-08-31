//
//  GroupEntry.swift
//  Atch
//
//  Created by Alex Barron on 8/30/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class GroupEntry: FriendEntry {
    override func awakeFromNib() {
        name.userInteractionEnabled = false
    }
}