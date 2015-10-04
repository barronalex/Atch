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
//        //PFInstallation.currentInstallation().setObject("", forKey: "userId")
//        PFInstallation.currentInstallation().saveInBackground()
        PFUser.logOutInBackgroundWithBlock() {
            (error) in
            if error == nil {
                
                self.performSegueWithIdentifier("fullylogout", sender: nil)
            }
            else {
                print("\(error)")
            }
        }
        
    }
    
    @IBAction func ATCH(sender: AnyObject) {
        PFCloud.callFunctionInBackground("sendLoginNotifications", withParameters: nil)
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
        let nsText: NSString = text!
        let trimmedText = nsText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        return trimmedText
    }
    
    func createColourBanners() {
        bannerHeight = (self.view.frame.height) / 12
        print("banner height: \(bannerHeight)")
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
        let installation = PFInstallation.currentInstallation()
        if let cuser = PFUser.currentUser()?.objectId {
            installation.setObject(cuser, forKey: parse_installation_userId)
            installation.saveInBackground()
        }
        
        createColourBanners()
        self.logOutTopConstraint.constant = self.bannerHeight - self.logOut.frame.height/2
        self.view.setNeedsDisplay()
        self.view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: "ATCH:"))
        
    }
    
    func friendLocationsUpdated(friendData: [PFObject]) {
        print("LOCATIONS FOUND")
        locationsFound = true
        if loadingScreen.hidden == false && picturesFound {
            self.performSegueWithIdentifier("atchtomap", sender: nil)
        }
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        print("PICTURES FOUND")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: profilePictureNotificationKey, object: nil)
        picturesFound = true
        if loadingScreen.hidden == false && locationsFound {
            self.performSegueWithIdentifier("atchtomap", sender: nil)
        }
    }
    
    

    
    override func viewDidAppear(animated: Bool) {
        
        if (PFUser.currentUser() == nil || !PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()!)) {
            print("PFUSER: \(PFUser.currentUser())")
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
        _friendManager.getPendingRequests(true)
        _friendManager.getPendingRequests(false)
        _friendManager.getFacebookFriends()
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

