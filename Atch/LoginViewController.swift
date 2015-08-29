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
    
    func moveKeyboardUpBy(delta: CGFloat, animationTime: NSNumber) {
        
        UIView.animateWithDuration(NSTimeInterval(animationTime), animations: {
            
            self.usernameInputConstraint.constant += delta
            self.view.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = kbRect.size.height - _currentKeyboardHeight
        _currentKeyboardHeight = kbRect.size.height
        moveKeyboardUpBy(delta, animationTime: animationTime)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = -kbRect.height
        _currentKeyboardHeight = 0
        println("keyboard hiding: \(kbRect.height)")
        moveKeyboardUpBy(delta, animationTime: animationTime)
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
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
//        let camera = GMSCameraPosition.cameraWithTarget(CLLocationCoordinate2DMake(51, 0), zoom: 8)
//        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera!)
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.bringSubviewToFront(loginView)
        self.view.bringSubviewToFront(filterView)
        filterView.userInteractionEnabled = false
    }
    
    func alreadySignedUp() {}
    
    override func viewDidDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    
}

