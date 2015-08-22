//
//  ViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/2/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import FBSDKCoreKit
import FBSDKLoginKit
import Parse
import Bolts
import CoreGraphics

class IntroViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //FacebookManager.downloadProfilePictures([PFUser.currentUser()!])
        
        
    }
    
    override func viewDidAppear(animated: Bool) {

        if (PFUser.currentUser() == nil || !PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()!)) {
            self.performSegueWithIdentifier("login", sender: nil)
        }
        //self.performSegueWithIdentifier("testmessenger", sender: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "testmessenger" {
            let destVC = segue.destinationViewController as! MessagingViewController
            
            destVC.toUsers = ["7InH7PS8bf", PFUser.currentUser()!.objectId!]
            //maybe pass other data about user (pic etc) later
            //can always use friendmap
            //might need tappedUserId to become an array for group convos
        }
    }
    

}
