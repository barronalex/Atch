//
//  UsernameViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/15/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class UsernameViewController: UIViewController, UsernameManagerDelegate {
    
    var usernameManager = UsernameManager()
    var username: String?
    
    @IBOutlet weak var usernamePrompt: UILabel!
    
    @IBOutlet weak var usernameField: UITextField!

    
    @IBAction func go() {
        print("here")
        usernameManager.delegate = self
        username = usernameField.text
        print(username)
        usernameManager.checkIfUsernameFree(username!)
        
    }
    
    func getUsername() {
        print("try again")
    }
    
    func usernameChosen() {
        //set username
        usernameManager.setUsername(username!)
        
    }
    
    func finished(){
        print("finished")
        self.performSegueWithIdentifier("postusername", sender: nil)
    }
    
}