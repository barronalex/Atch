//
//  AtchMapViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/2/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import GoogleMaps
import Parse
import Bolts
import CoreLocation

class AtchMapViewController: UIViewController, LocationUpdaterDelegate, FriendManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet weak var bannerView: UIView!
    
    @IBOutlet weak var bannerConstraint: NSLayoutConstraint!
    
    var mapView: GMSMapView?
    
    @IBOutlet weak var friendsButton: UIButton!
    
    @IBOutlet weak var logout: UIButton!
    
    var friendManager = FriendManager()
    var curLocation = CLLocationCoordinate2D()
    var friends = [PFObject]()
    var friendPics = [String:UIImage]()
    var firstLocation = true
    var userMarkers = [String:GMSMarker]()
    var camera: GMSCameraPosition?
    var tappedUserId: String?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        _locationUpdater?.delegate = self
        mapView = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
        self.view.addSubview(mapView!)
        self.view.bringSubviewToFront(friendsButton)
        self.view.bringSubviewToFront(logout)
        mapView?.delegate = self
        firstLocation = true
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        friendManager.delegate = self
        if friends.count == 0 {
           friendManager.getFriends()
        }
        if friendPics.count == 0 {
            FacebookManager.downloadProfilePictures(friends)
        }
        if _locationUpdater == nil {
            _locationUpdater = LocationUpdater()
            _locationUpdater?.startUpdates()
            _locationUpdater?.delegate = self
        }
        let tapGesture = UITapGestureRecognizer(target: self, action: "bannerTapped")
        self.bannerView.addGestureRecognizer(tapGesture)
    }
    
    func bannerTapped() {
        if tappedUserId != PFUser.currentUser()!.objectId! {
            self.performSegueWithIdentifier("maptochat", sender: nil)
        }
    }

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "maptochat" {
            let destVC = segue.destinationViewController as! MessagingViewController
            
            destVC.toUsers = [tappedUserId!, PFUser.currentUser()!.objectId!]
        }
        if segue.identifier == "maptofriends" {
            let destVC = segue.destinationViewController as! FriendsViewController
            destVC.friends = self.friends
            destVC.friendPics = self.friendPics
        }
        if segue.identifier == "logout" {
            mapView?.myLocationEnabled = false
            _locationUpdater?.stopUpdates()
        }
    }

}

//Map Methods
extension AtchMapViewController {
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        println("tapped marker")
        tappedUserId = marker.userData as? String
        println("marker user id: \(tappedUserId!)")
        //mapView!.animateToCameraPosition(GMSCameraPosition.cameraWithTarget(marker.position, zoom: 6))
//
        //put up banner
        self.view.bringSubviewToFront(bannerView)
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(0.5), animations: {
            self.bannerConstraint.constant = 0
            self.view.layoutIfNeeded()
        })
        return true
    }
    
    private func setMarkerImage(marker: GMSMarker, userId: String) {
        if let image = friendPics[userId] {
            marker.icon = image
            marker.icon = ImageProcessor.createCircle(image)
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    private func createNewMarker(user: PFObject, location: PFGeoPoint?) {
        let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude))
        marker.map = mapView
        userMarkers[user.objectId!] = marker
        setMarkerImage(marker, userId: user.objectId!)
        marker.userData = user.objectId!
    }
    
    func locationUpdated(location: CLLocationCoordinate2D) {
        print("location updated")
        curLocation = location
        if firstLocation {
            println("first location")
            _locationUpdater?.sendLocationToServer()
            _locationUpdater?.getFriendLocationsFromServer()
            camera = GMSCameraPosition.cameraWithTarget(location, zoom: 6)
            mapView!.animateToCameraPosition(camera)
            mapView!.myLocationEnabled = true
            firstLocation = false
        }
    }
}

//Friend Methods
extension AtchMapViewController {
    
    func friendListFound(friends: [PFUser]) {
        //map user ids to user objects
        FacebookManager.downloadProfilePictures(friends)
        self.friends = friends
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        var dataMap = notification.userInfo as! [String:[String:UIImage]]
        println("pictures received")
        friendPics += dataMap["images"]!
        for (userId, marker) in userMarkers {
            setMarkerImage(marker, userId: userId)
        }
    }
    
    func friendLocationsUpdated(friendData: [PFObject]) {
        //display locations
        print("friends location updated")
        //make array of markers if first time
        //display them
        for data in friendData {
            let location = data.objectForKey("location") as? PFGeoPoint
            if location != nil {
                //make marker to display location
                let user = data.objectForKey("user") as! PFObject
                if let marker = userMarkers[user.objectId!] {
                    marker.position = CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude)
                    marker.userData = user.objectId!
                    
                }
                else {
                    createNewMarker(user, location: location)
                }
                
                print("location: \(location!.latitude) \(location!.longitude)")
                
            }
        }
    }
    
    //to fufill delegates
    func friendRequestSent() { }
    func friendRequestAccepted() { }
    func pendingFromRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func pendingToRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func facebookFriendsFound(facebookFriends: [PFUser]) { }
    func searchFinished(searchResults: [PFUser]) { }
    
}