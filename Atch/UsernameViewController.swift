//
//  UsernameViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/15/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse
import FBSDKCoreKit
import FBSDKLoginKit

class UsernameViewController: UIViewController, UsernameManagerDelegate, FacebookManagerDelegate, UITextFieldDelegate {
    
    var loginVC: LoginViewController?
    
    var facebookManager = FacebookManager()
    var usernameManager = UsernameManager()
    var doneEditing = false
    
    @IBOutlet weak var usernameField: UITextField!
    
    @IBOutlet weak var usernameLabel: UILabel!
    


    
    @IBAction func go(sender: AnyObject) {
        doneEditing = true
        if usernameLabel.text! == "Username Taken" || usernameLabel.text! == "Username Invalid - Letters/Numbers Only" {
            return
        }
        if let username = usernameField.text {
            print(username)
            usernameManager.checkIfUsernameFree(username)
        }
    }
    
    override func viewDidLoad() {
        usernameField.autocorrectionType = UITextAutocorrectionType.No
        facebookManager.delegate = self
        usernameManager.delegate = self
        usernameField.delegate = self
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("textFieldDidChange:"), name: UITextFieldTextDidChangeNotification, object: usernameField)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.loginVC?.moveKeyboardUp()
    }
    
    func textFieldDidChange(notification: NSNotification) {
        if let username = usernameField.text {
            usernameManager.checkIfUsernameFree(username)
        }
        
    }
    
    func nameInvalid() {
        usernameLabel.text = "Username Invalid - Letters/Numbers Only"
        usernameLabel.textColor = UIColor.redColor()
    }
    
    func getUsername() {
        usernameLabel.text = "Username Taken"
        usernameLabel.textColor = UIColor.redColor()
    }
    
    func usernameChosen() {
        println("her")
        if usernameField.text == "" {
            usernameLabel.text = "Choose a Username"
            usernameLabel.textColor = UIColor.whiteColor()
            return
        }
        if doneEditing == false {
            println("username free")
            usernameLabel.text = "Username Free"
            usernameLabel.textColor = UIColor.greenColor()
            return
        }
        doneEditing = false
        //login with Parse + Facebook
        if FBSDKAccessToken.currentAccessToken() == nil {
            facebookManager.loginUserToParseWithoutToken()
        }
        else {
            facebookManager.loginUserToParseWithToken()
        }
    }
    
    func finished(){
        print("finished")
        self.performSegueWithIdentifier("postusername", sender: nil)
    }
    
    func parseLoginSucceeded() {
        println("signed up to parse with facebook")
        usernameManager.setUsername(usernameField.text!)
    }
    func alreadySignedUp() {
        println("log user in and tell them that they've already signed up with facebook")
        self.performSegueWithIdentifier("postusername", sender: nil)
    }
    
    func facebookLoginSucceeded() {}
    func facebookLoginFailed(reason: String) {}
    func goToSignUp() {}
    func parseLoginFailed() {}
    
    
    
}