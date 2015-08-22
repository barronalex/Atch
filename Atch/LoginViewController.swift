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
    
    @IBOutlet weak var filterView: UIView!
    
    @IBAction func facebookLogin() {
        facebookManager.delegate = self
        facebookManager.login()
    }
    
    
    @IBAction func signUp() {
        facebookManager.delegate = self
        facebookManager.login()
    }
    
    override func viewDidAppear(animated: Bool) {
        self.view.bringSubviewToFront(filterView)
        filterView.userInteractionEnabled = false
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let camera = GMSCameraPosition.cameraWithTarget(CLLocationCoordinate2DMake(51, 0), zoom: 8)
        let mapView = GMSMapView.mapWithFrame(CGRectZero, camera: camera!)
        mapView.mapType =
        //mapView!.myLocationEnabled = true
        //self.backgroundMapView = mapView
    }
    
    
}

