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
        if name == "" {
            self.delegate?.usernameChosen()
            return
        }
        if !checkIfValid(name) {
            self.delegate?.nameInvalid()
            return
        }
        let query = PFUser.query()!
        print("checking if free")
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
                else {
                    self.delegate?.usernameChosen()
                }
            } else {
                print("error")
                
            }
        }
    }
    
    func checkIfValid(name: String) -> Bool {
        let characterSet = NSCharacterSet.alphanumericCharacterSet()
        if name.rangeOfCharacterFromSet(characterSet.invertedSet, options: .CaseInsensitiveSearch) == nil && count(name) < 20 {
            return true
        }
        return false
    }
    
    func setUsername(name: String) {
        PFUser.currentUser()?.setObject(name, forKey: "username")
        PFUser.currentUser()?.setObject(name.lowercaseString, forKey: "queryUsername")
        PFUser.currentUser()?.saveInBackground()
        self.delegate?.finished()
    }
    
}