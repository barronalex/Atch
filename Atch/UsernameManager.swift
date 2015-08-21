//
//  UsernameManager.swift
//  Atch
//
//  Created by Alex Barron on 8/15/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse
import Bolts

class UsernameManager {
    
    var delegate: UsernameManagerDelegate?
    
    func checkIfUsernameFree(name: String) {
        let query = PFUser.query()!
        print("querying")
        query.whereKey("username", equalTo: name)
        query.findObjectsInBackgroundWithBlock {
            (objects: [AnyObject]?, error: NSError?) -> Void in
            
            if error == nil {
                if let objects = objects as? [PFObject] {
                    if objects.count == 0 {
                        self.delegate?.usernameChosen()
                    }
                    else {
                        self.delegate?.getUsername()
                    }
                }
            } else {
                print("error")
                
            }
        }
    }
    
    func setUsername(name: String) {
        PFUser.currentUser()?.setObject(name, forKey: "username")
        PFUser.currentUser()?.setObject("t", forKey: "usernameSet")
        PFUser.currentUser()?.saveInBackground()
        self.delegate?.finished()
    }
    
}