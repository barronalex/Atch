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
    
    @IBOutlet var bannerGesture: UIPanGestureRecognizer!
    
    @IBOutlet weak var bannerLabel: UILabel!
    
    @IBOutlet weak var bannerView: UIView!
    
    @IBOutlet weak var topContainerConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var bannerConstraint: NSLayoutConstraint!
    
    var mapView: GMSMapView?
    
    @IBOutlet weak var friendsButton: UIButton!
    
    @IBOutlet weak var logout: UIButton!
    
    var containerVC: MapContainerViewController?
    var friendManager = FriendManager()
    var friends = [PFObject]()
    var friendMap = [String:PFObject]()
    var friendPics = [String:UIImage]()
    var firstLocation = true
    var userMarkers = [String:GMSMarker]()
    var camera: GMSCameraPosition?
    var tappedUserId: String?
    var bannerUp = false
    var bannerAtTop = false
    
    let zeroMapInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
    let bannerMapInsets = UIEdgeInsetsMake(0.0, 0.0, 120, 0.0)
    let upwardsMapCorrection: CGFloat = 100
    let downwardsMapCorrection: CGFloat = 100
    let topMargin: CGFloat = 20
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        self.containerHeightConstraint.constant = self.view.frame.height - bannerView.frame.height
        self.view.layoutIfNeeded()
        self.topContainerConstraint.constant = self.view.frame.height - 20
        self.view.layoutIfNeeded()
        setUpLocationManager()
        setUpMap()
        setUpFriendManager()
        let tapGesture = UITapGestureRecognizer(target: self, action: "bannerTapped")
        self.bannerView.addGestureRecognizer(tapGesture)
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
            destVC.friendMap = self.friendMap
        }
        if segue.identifier == "logout" {
            mapView?.myLocationEnabled = false
            _locationUpdater?.stopUpdates()
        }
        if segue.identifier == "mapcontainerembed" {
            let destVC = segue.destinationViewController as! MapContainerViewController
            containerVC = destVC
        }
    }

    @IBAction func hereButton() {
        let childVCs = containerVC?.childVCs
        if let childVCs = childVCs {
            let messageVC = childVCs[0] as! MessagingViewController
            messageVC.messenger.sendMessage("meet here")
        }
    }
    
    @IBAction func thereButton() {
        let childVCs = containerVC?.childVCs
        if let childVCs = childVCs {
            let messageVC = childVCs[0] as? MessagingViewController
            messageVC?.messenger.sendMessage("meet there")
        }
    }
    func bringUpMessagesScreen() {
        putBannerUp()
        bannerAtTop = false
        bannerTapped()
    }
}

//Initialisation Methods
extension AtchMapViewController {
    func setUpFriendManager() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("friendProfilePicturesReceived:"), name: profilePictureNotificationKey, object: nil)
        friendManager.delegate = self
        if friends.count == 0 {
            friendManager.getFriends()
        }
        if friendPics.count == 0 {
            FacebookManager.downloadProfilePictures(friends)
        }
    }
    
    func setUpLocationManager() {
        _locationUpdater?.delegate = self
        firstLocation = true
        if _locationUpdater == nil {
            _locationUpdater = LocationUpdater()
            _locationUpdater?.delegate = self
            _locationUpdater?.startUpdates()
        }
        else if !_locationUpdater!.updating {
            _locationUpdater?.startUpdates()
        }
        
    }
    
    func setUpMap() {
        
        if let location = _locationUpdater!.getLocation() {
            mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height), camera: GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: 6))
            _locationUpdater?.sendLocationToServer()
            _locationUpdater?.getFriendLocationsFromServer()
            mapView!.myLocationEnabled = true
            firstLocation = false
            
        }
        else {
            mapView = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            
        }
        self.view.addSubview(mapView!)
        self.view.bringSubviewToFront(friendsButton)
        self.view.bringSubviewToFront(logout)
        mapView?.delegate = self
    }

}

//Banner Methods
extension AtchMapViewController {
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        
        if recognizer.state == UIGestureRecognizerState.Ended && self.bannerConstraint.constant > 0 {
            if self.bannerConstraint.constant == self.bannerView.frame.height - self.topMargin {
                return
            }
            bannerTapped()
            return
        }
        let yTranslation = recognizer.translationInView(self.view).y
        if let view = recognizer.view {
            if (self.bannerConstraint.constant - yTranslation) > (self.view.frame.height - bannerView.frame.height) {
                self.bannerConstraint.constant = self.view.frame.height - bannerView.frame.height
                self.topContainerConstraint.constant = self.bannerView.frame.height - topMargin
            }
            else if (self.bannerConstraint.constant - yTranslation) < 0 {
                self.bannerConstraint.constant = 0
                self.topContainerConstraint.constant = self.view.frame.height - topMargin
            }
            else {
                self.bannerConstraint.constant -= yTranslation
                self.topContainerConstraint.constant += yTranslation
            }
            
        }
        recognizer.setTranslation(CGPointZero, inView: self.view)
    }
    
    func bannerTapped() {
        if !bannerAtTop {
            UIView.animateWithDuration(NSTimeInterval(0.4), animations: {
                self.topContainerConstraint.constant = self.bannerView.frame.height - self.topMargin
                self.bannerConstraint.constant = self.view.frame.height - self.bannerView.frame.height
                self.view.layoutIfNeeded()
            })
            bannerAtTop = true
        }
        else {
            putBannerDown()
        }
        
    }
    
    func putBannerUp() {
        
        //put up banner
        println("friend map count: \(friendMap.count)")
        println("tapped id: \(tappedUserId)")
        bannerLabel.text = friendMap[self.tappedUserId!]?.objectForKey("fullname") as? String
        println("BANNER TEXT: \(bannerLabel.text)")
        if bannerLabel.text == nil {
            bannerLabel.text = friendMap[self.tappedUserId!]?.objectForKey("username") as? String
        }
        self.view.bringSubviewToFront(bannerView)
        self.view.bringSubviewToFront(containerView)
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(0.5), animations: {
            self.bannerConstraint.constant = 0
            self.mapView?.padding = self.bannerMapInsets
            self.view.layoutIfNeeded()
        })
        bannerUp = true
    }
    
    func putBannerDown() {
        self.view.endEditing(true)
        UIView.animateWithDuration(NSTimeInterval(0.4), animations: {
            self.topContainerConstraint.constant = self.view.frame.height - 20
            self.bannerConstraint.constant = -self.bannerView.frame.height
            self.view.layoutIfNeeded()
            }, completion: {
                (finished) in
                self.containerVC?.removeChildren()
        })
        bannerUp = false
        bannerAtTop = false
        mapView?.padding = zeroMapInsets
    }

}

//Map Methods
extension AtchMapViewController {
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        println("tapped marker")
        tappedUserId = marker.userData as? String
        println("marker user id: \(tappedUserId!)")
        var toUsers = [tappedUserId!, PFUser.currentUser()!.objectId!]
        sort(&toUsers)
        containerVC?.goToMessages(toUsers)
//        self.view.bringSubviewToFront(containerView)
        self.view.layoutIfNeeded()
        putBannerUp()
        correctMarkerPosition(marker)
        return true
    }
    
    func correctMarkerPosition(marker: GMSMarker) {
        if var point = mapView?.projection.pointForCoordinate(marker.position) {
            if point.y > self.view.frame.height - self.bannerView.frame.height - 20 {
                
                point.y = point.y - upwardsMapCorrection
                let cameraUpdate = GMSCameraUpdate.setTarget(mapView!.projection.coordinateForPoint(point))
                mapView?.animateWithCameraUpdate(cameraUpdate)
            }
            else if point.y < self.bannerView.frame.height - 20 || point.x < 40 || point.x > self.view.frame.width - 40 {
                let cameraUpdate = GMSCameraUpdate.setTarget(mapView!.projection.coordinateForPoint(point))
                mapView?.animateWithCameraUpdate(cameraUpdate)
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
        marker.map = mapView
        userMarkers[user.objectId!] = marker
        setMarkerImage(marker, userId: user.objectId!)
        marker.userData = user.objectId!
    }
    
    func locationUpdated(location: CLLocationCoordinate2D) {
        //print("location updated")
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
        for friend in friends {
            friendMap[friend.objectId!] = friend
        }
        self.friends = friends
        if self.tappedUserId != nil {
            bannerLabel.text = friendMap[self.tappedUserId!]?.objectForKey("fullname") as? String
            println("BANNER TEXT POST FRIENDS: \(bannerLabel.text)")
            if bannerLabel.text == nil {
                bannerLabel.text = friendMap[self.tappedUserId!]?.objectForKey("username") as? String
            }
        }
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