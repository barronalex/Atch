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
import GoogleMaps

class IntroViewController: UIViewController, LocationUpdaterDelegate {
    
    var bannerHeight: CGFloat = 0
    
    @IBOutlet weak var loadingScreen: UIView!
    
    @IBOutlet weak var logOutTopConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var logOut: UIButton!
    
    @IBAction func logout() {
        PFInstallation.currentInstallation().setObject("", forKey: "userId")
        PFInstallation.currentInstallation().saveInBackground()
        PFUser.logOutInBackgroundWithBlock() {
            (error) in
            if error == nil {
                
                self.performSegueWithIdentifier("fullylogout", sender: nil)
            }
            else {
                println("\(error)")
            }
        }
        
    }
    
    @IBAction func ATCH(sender: AnyObject) {
        if picturesFound && locationsFound {
            self.performSegueWithIdentifier("atchtomap", sender: nil)
        }
        else {
            //show loading screen
            loadingScreen.hidden = false
            self.view.bringSubviewToFront(loadingScreen)
        }
    }
    
    var locationsFound = false
    var picturesFound = false
    
    func trimSpaces(text: String?) -> String? {
        if text == nil {
            return text
        }
        var nsText: NSString = text!
        var trimmedText = nsText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        return trimmedText
    }
    
    func createColourBanners() {
        bannerHeight = (self.view.frame.height) / 12
        println("banner height: \(bannerHeight)")
        //let's say 12 banners
        let colour = ColourGenerator.generateRandomColour()
        for var i: CGFloat = 0; i < 12; i++ {
            let banner = UIView(frame: CGRectMake(0, i * bannerHeight, self.view.frame.width, bannerHeight))
            banner.backgroundColor = colour
            banner.alpha = 1 - (i * 0.05)
           // banner.backgroundColor =
            self.view.addSubview(banner)
            self.view.sendSubviewToBack(banner)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        createColourBanners()
        logOutTopConstraint.constant = bannerHeight - logOut.frame.height/2
        self.view.setNeedsDisplay()
    }
    
    func friendLocationsUpdated(friendData: [PFObject]) {
        println("LOCATIONS FOUND")
        locationsFound = true
        if loadingScreen.hidden == false && picturesFound {
            self.performSegueWithIdentifier("atchtomap", sender: nil)
        }
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("PICTURES FOUND")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: profilePictureNotificationKey, object: nil)
        picturesFound = true
        if loadingScreen.hidden == false && locationsFound {
            self.performSegueWithIdentifier("atchtomap", sender: nil)
        }
    }
    
    

    
    override func viewDidAppear(animated: Bool) {
        
        if (PFUser.currentUser() == nil || !PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()!)) {
            println("PFUSER: \(PFUser.currentUser())")
            self.performSegueWithIdentifier("login", sender: nil)
            return
        }
        if _mapView == nil {
            _mapView = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            _mapView!.camera = stanfordCam
            _mapView!.settings.rotateGestures = false
        }
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        _locationUpdater.delegate = self
        _friendManager.getFriends()
    }
    
    override func viewDidDisappear(animated: Bool) {
        
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
        
    func locationUpdated(location: CLLocationCoordinate2D) { }

}

