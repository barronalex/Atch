//
//  FriendEntry.swift
//  Atch
//
//  Created by Alex Barron on 8/28/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class FriendEntry: UITableViewCell {
    
    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var acceptButton: UIButton!
    
    override func awakeFromNib() {
        username.userInteractionEnabled = false
        name.userInteractionEnabled = false
    }
}

