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
    
    
    @IBOutlet weak var mainMapView: GMSMapView!
    
    @IBOutlet weak var friendsButton: UIButton!
    
    
    var friendManager = FriendManager()
    var locationUpdater = LocationUpdater()
    var curLocation = CLLocationCoordinate2D()
    var friendMap = [String:PFObject]()
    var friendPics = [String:UIImage]()
    var firstLocation = true
    var userMarker = GMSMarker()
    var userMarkers = [String:GMSMarker]()
    var camera: GMSCameraPosition?
    var tappedUserId: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.bringSubviewToFront(friendsButton)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        friendManager.delegate = self
        friendManager.getFriends()
        locationUpdater.startUpdates()
    }
    
    func locationUpdated(location: CLLocationCoordinate2D) {
        print("location updated")
        curLocation = location
        if firstLocation {
            locationUpdater.sendLocationToServer()
            locationUpdater.getFriendLocationsFromServer()
            camera = GMSCameraPosition.cameraWithTarget(location, zoom: 6)
            mainMapView.animateToCameraPosition(camera)
            mainMapView.delegate = self
            mainMapView.myLocationEnabled = true
            firstLocation = false
//            userMarker.map = mainMapView
//            userMarker.userData = PFUser.currentUser()!.objectId!
        }
        //userMarker.position = location
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
                    setMarkerImage(marker, userId: user.objectId!)
                    marker.userData = user.objectId!
                    
                }
                else {
                    createNewMarker(user, location: location)
                }
                
                print("location: \(location!.latitude) \(location!.longitude)")
                
            }
        }
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
        marker.map = mainMapView
        userMarkers[user.objectId!] = marker
        setMarkerImage(marker, userId: user.objectId!)
        marker.userData = user.objectId!
    }
    
    func friendListFound(friends: [PFUser]) {
        //map user ids to user objects
        FacebookManager.downloadProfilePictures(friends)
        for friend in friends {
            friendMap[friend.objectId!] = friend
        }
        locationUpdater.delegate = self
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        var dataMap = notification.userInfo as! [String:[String:UIImage]]
        println("pictures received")
        friendPics += dataMap["images"]!
    }
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        println("tapped marker")
        tappedUserId = marker.userData as? String
        println("marker user id: \(tappedUserId!)")
        if tappedUserId != PFUser.currentUser()!.objectId! {
            self.performSegueWithIdentifier("maptochat", sender: nil)
        }
        return true
        
        
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "maptochat" {
            let destVC = segue.destinationViewController as! MessagingViewController
            
            destVC.toUsers = [tappedUserId!, PFUser.currentUser()!.objectId!]
            //maybe pass other data about user (pic etc) later
            //can always use friendmap
            //might need tappedUserId to become an array for group convos
        }
    }
    
    
    //to fufill delegates
    func friendRequestSent() { }
    func friendRequestAccepted() { }
    func pendingRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func facebookFriendsFound(facebookFriends: [PFUser]) { }
    func searchFinished(searchResults: [PFUser]) { }

}