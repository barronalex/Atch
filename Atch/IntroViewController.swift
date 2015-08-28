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
    
    @IBOutlet weak var image: UIImageView!
    
    @IBAction func logout() {
        PFUser.logOutInBackgroundWithBlock() {
            (error) in
            if error == nil {
                self.performSegueWithIdentifier("fullylogout", sender: nil)
            }
            else {
                println("\(error)")
//                UIAlertController.
//                self.presentViewController(UIAlertController(title: "logout failed", message: "we were unable to log you out at this time", preferredStyle: UIAlertControllerStyle.Alert), animated: false, completion: nil)
            }
        }
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.sendSubviewToBack(image)
    }
    
    override func viewDidAppear(animated: Bool) {
//        if ["a", "b"] == ["b", "a"] {
//            println("YESSSSSSSS")
//        }
//        self.presentViewController(UIAlertController(title: "logout failed", message: "we were unable to log you out at this time", preferredStyle: UIAlertControllerStyle.Alert), animated: false, completion: nil)
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
            
            destVC.toUsers = ["hQQXBj9DS9", PFUser.currentUser()!.objectId!]
            //maybe pass other data about user (pic etc) later
            //can always use friendmap
            //might need tappedUserId to become an array for group convos
        }
    }
    

}

