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

class LoginViewController: UIViewController, FacebookManagerDelegate {
    
    var facebookManager = FacebookManager()
    
    @IBOutlet weak var backgroundMapView: UIView!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var filterView: UIView!
    
    @IBOutlet weak var loginView: UIView!
    
    @IBOutlet weak var login: UIButton!
    
    @IBOutlet weak var signup: UIButton!
    
    @IBAction func facebookLogin() {
        facebookManager.delegate = self
        facebookManager.login()
    }
    
    @IBOutlet weak var usernameInputConstraint: NSLayoutConstraint!
    
    @IBAction func signUp() {
        showUsernameInput()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.bringSubviewToFront(loginView)
        self.view.bringSubviewToFront(filterView)
        filterView.userInteractionEnabled = false
    }
    
    func friendRequestSent() {
        print("request sent")
    }
    
    func friendRequestAccepted() {
        
    }
    
    func facebookLoginSucceeded() {
        print("login succeeded")
        login.hidden = true
        signup.hidden = true
        facebookManager.checkIfFacebookAssociatedWithParse()

    }
    
    func facebookLoginFailed(reason: String) {
        println("login failed")
    }
    
    func parseLoginSucceeded() {
        println("login completed")
        self.performSegueWithIdentifier("postlogin", sender: nil)
    }
    
    func parseLoginFailed() {
        
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
    
    func goToSignUp() {
        showUsernameInput()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        hideUsernameInput()
        
        let camera = GMSCameraPosition.cameraWithTarget(CLLocationCoordinate2DMake(51, 0), zoom: 8)
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera!)
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
    
    func alreadySignedUp() {}
    
    
}

