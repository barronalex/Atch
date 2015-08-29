//
//  LoginViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/7/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import GoogleMaps
import CoreLocation
import Parse

class LoginViewController: UIViewController, FacebookManagerDelegate {
    
    var facebookManager = FacebookManager()
    
    @IBOutlet weak var backgroundMapView: GMSMapView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var filterView: UIView!
    
    @IBOutlet weak var loginView: UIView!
    
    @IBOutlet weak var login: UIButton!
    
    @IBOutlet weak var signup: UIButton!
    
    @IBOutlet weak var usernameInputConstraint: NSLayoutConstraint!
    
    @IBAction func facebookLogin() {
        facebookManager.delegate = self
        facebookManager.login()
    }
    
    @IBAction func signUp() {
        let tapGesture = UITapGestureRecognizer(target: self, action: "mapTapped")
        self.filterView.addGestureRecognizer(tapGesture)
        filterView.userInteractionEnabled = true
        showUsernameInput()
    }
    
    func goToSignUp() {
        showUsernameInput()
    }

    func mapTapped() {
        filterView.userInteractionEnabled = false
        hideUsernameInput()
    }
    
    func friendRequestSent() {
        print("request sent")
    }
    
    func friendRequestAccepted() {
        println("request accepted")
    }
    
    func facebookLoginSucceeded() {
        print("login succeeded")
        login.setTitle("Logging In...", forState: .Normal)
        login.enabled = false
        signup.enabled = false
        facebookManager.checkIfFacebookAssociatedWithParse()

    }
    
    func facebookLoginFailed(reason: String) {
        println("login failed")
    }
    
    func parseLoginSucceeded() {
        println("login completed")
        let installation = PFInstallation.currentInstallation()
        installation.setObject(PFUser.currentUser()!.objectId!, forKey: parse_installation_userId)
        installation.saveInBackground()
        self.performSegueWithIdentifier("postlogin", sender: nil)
    }
    
    func parseLoginFailed() {
        println("parse login failed")
    }
    
    func moveKeyboardUp() {
        
        UIView.animateWithDuration(0.25, animations: {
            
            self.usernameInputConstraint.constant = 155
            self.view.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    func moveKeyboardDown() {
        
        UIView.animateWithDuration(0.25, animations: {
            
            self.usernameInputConstraint.constant = 0
            self.view.layoutIfNeeded()
            
            }, completion: nil)

    }
    
    func hideUsernameInput() {
        containerView.userInteractionEnabled = false
        containerView.hidden = true
    }
    
    func showUsernameInput() {
        self.view.bringSubviewToFront(containerView)
        containerView.hidden = false
        containerView.userInteractionEnabled = true
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "usernameinput" {
            println("segueing")
            let destVC = segue.destinationViewController as! UsernameViewController
            destVC.loginVC = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideUsernameInput()
        var mapInsets = UIEdgeInsetsMake(0.0, 0.0, self.view.frame.height - 170, 0.0)
        self.backgroundMapView.padding = mapInsets
        
//        let camera = GMSCameraPosition.cameraWithTarget(CLLocationCoordinate2DMake(51, 0), zoom: 8)
//        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera!)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.bringSubviewToFront(loginView)
        self.view.bringSubviewToFront(filterView)
        filterView.userInteractionEnabled = false
    }
    
    func alreadySignedUp() {}
    
    
}

