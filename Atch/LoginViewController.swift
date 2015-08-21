//
//  LoginViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/7/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit

class LoginViewController: UIViewController, FacebookManagerDelegate {
    
    var facebookManager = FacebookManager()
    
    @IBAction func facebookLogin() {
        facebookManager.delegate = self
        facebookManager.login()
    }
    
    @IBAction func signUp() {
        facebookManager.delegate = self
        facebookManager.login()
    }
    
    func usernameNeeded() {
        //segue to username getting screen
        self.performSegueWithIdentifier("username", sender: nil)
    }
    
    func friendRequestSent() {
        print("request sent")
    }
    
    func friendRequestAccepted() {
        
    }
    
    func loginFinished() {
        print("login finished")
        facebookManager.getFriendList()
        
        self.performSegueWithIdentifier("postlogin", sender: nil)
        
    }
    
    
}

