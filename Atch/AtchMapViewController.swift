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
    
    @IBOutlet weak var circleImageLeft: UIImageView!
    
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var bannerConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var friendsButton: UIButton!
    
    @IBOutlet weak var logout: UIButton!
    
    
    var mapTapGesture: UITapGestureRecognizer?
    var containerVC: MapContainerViewController?
    var firstLocation = true
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
        println("loading Atch")
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
        if segue.identifier == "logoutfrommap" {
            putBannerDown()
            _mapView?.myLocationEnabled = false
            _mapView?.settings.myLocationButton = false
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
        _friendManager.delegate = self
        if _friendManager.friends.count == 0 {
            _friendManager.getFriends()
        }
        if _friendManager.friendPics.count == 0 {
            FacebookManager.downloadProfilePictures(_friendManager.friends)
        }
    }
    
    func setUpLocationManager() {
        firstLocation = true
        if _locationUpdater == nil {
            println("here")
            _locationUpdater = LocationUpdater()
            _locationUpdater!.delegate = self
            _locationUpdater!.startUpdates()
        }
        else if !_locationUpdater!.updating {
            _locationUpdater?.startUpdates()
        }
         _locationUpdater?.delegate = self
        
    }
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        if bannerUp {
            putBannerDown()
        }
    }
    
    func setUpMap() {
        if _locationUpdater == nil {
            println("this is nillll")
        }
        if _locationUpdater?.getLocation() != nil {
            println("this is also nil")
        }
        
        if let location = _locationUpdater!.getLocation() {
            if _mapView == nil {
                _mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height), camera: GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: 6))
            }
            _locationUpdater?.sendLocationToServer()
            _locationUpdater?.getFriendLocationsFromServer()
            _mapView!.myLocationEnabled = true
            firstLocation = false
            
        }
        else {
            if _mapView == nil {
                _mapView = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            }
            
        }
        self.view.addSubview(_mapView!)
        _mapView!.settings.myLocationButton = true
        self.view.bringSubviewToFront(circleImageLeft)
        self.view.bringSubviewToFront(friendsButton)
        self.view.bringSubviewToFront(logout)
        _mapView?.delegate = self
        //addMarkers()
    }
    
//    func addMarkers() {
//        for (user, marker) in _friendManager.userMarkers {
//            let marker = GMSMarker(position: marker.position)
//            marker.map = _mapView!
//            setMarkerImage(marker, userId: user)
//            marker.userData = user
//        }
//    }

}

//Banner Methods
extension AtchMapViewController {
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended && self.bannerConstraint.constant > 0 {
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
            lowerBanner()
        }
        
    }
    
    func lowerBanner() {
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(0.5), animations: {
            self.bannerConstraint.constant = 0
            self.topContainerConstraint.constant = self.view.frame.height - 20
            _mapView?.padding = self.bannerMapInsets
            self.view.layoutIfNeeded()
        })
        bannerAtTop = false
        self.view.endEditing(true)
    }
    
    func putBannerUp() {
        var toUsers = [tappedUserId!, PFUser.currentUser()!.objectId!]
        containerVC?.goToMessages(toUsers)
        //put up banner
        println("friend map count: \(_friendManager.friendMap.count)")
        println("tapped id: \(tappedUserId)")
        bannerLabel.text = _friendManager.friendMap[self.tappedUserId!]?.objectForKey(parse_user_fullname) as? String
        println("BANNER TEXT: \(bannerLabel.text)")
        if bannerLabel.text == nil {
            bannerLabel.text = _friendManager.friendMap[self.tappedUserId!]?.objectForKey(parse_user_username) as? String
        }
        self.view.bringSubviewToFront(bannerView)
        self.view.bringSubviewToFront(containerView)
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(0.5), animations: {
            self.bannerConstraint.constant = 0
            _mapView?.padding = self.bannerMapInsets
            self.view.layoutIfNeeded()
        })
        bannerUp = true
    }
    
    func putBannerDown() {
        self.view.endEditing(true)
        UIView.animateWithDuration(NSTimeInterval(0.4), animations: {
            self.topContainerConstraint.constant = self.view.frame.height - 20
            self.bannerConstraint.constant = -self.bannerView.frame.height
            _mapView?.padding = self.zeroMapInsets
            self.view.layoutIfNeeded()
            }, completion: {
                (finished) in
                self.containerVC?.removeChildren()
        })
        bannerUp = false
        bannerAtTop = false
    }

}

//Map Methods
extension AtchMapViewController {
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        println("tapped marker")
        tappedUserId = marker.userData as? String
        println("marker user id: \(tappedUserId!)")
        putBannerUp()
        correctMarkerPosition(marker)
        return true
    }
    
    func correctMarkerPosition(marker: GMSMarker) {
        if var point = _mapView?.projection.pointForCoordinate(marker.position) {
            if point.y > self.view.frame.height - self.bannerView.frame.height - 20 {
                
                point.y = point.y - upwardsMapCorrection
                let cameraUpdate = GMSCameraUpdate.setTarget(_mapView!.projection.coordinateForPoint(point))
                _mapView?.animateWithCameraUpdate(cameraUpdate)
            }
            else if point.y < self.bannerView.frame.height - 20 || point.x < 40 || point.x > self.view.frame.width - 40 {
                let cameraUpdate = GMSCameraUpdate.setTarget(_mapView!.projection.coordinateForPoint(point))
                _mapView?.animateWithCameraUpdate(cameraUpdate)
            }
        }
    }
    
    private func setMarkerImage(marker: GMSMarker, userId: String) {
        if let image = _friendManager.friendPics[userId] {
            marker.icon = image
            marker.icon = ImageProcessor.createCircle(image)
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        }
    }
    
    private func createNewMarker(user: PFObject, location: PFGeoPoint?) {
        let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude))
        marker.map = _mapView
        _friendManager.userMarkers[user.objectId!] = marker
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
            _mapView!.animateToCameraPosition(camera)
            _mapView!.myLocationEnabled = true
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
            _friendManager.friendMap[friend.objectId!] = friend
        }
        if self.tappedUserId != nil {
            bannerLabel.text = _friendManager.friendMap[self.tappedUserId!]?.objectForKey(parse_user_fullname) as? String
            println("BANNER TEXT POST FRIENDS: \(bannerLabel.text)")
            if bannerLabel.text == nil {
                bannerLabel.text = _friendManager.friendMap[self.tappedUserId!]?.objectForKey(parse_user_fullname) as? String
            }
        }
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("pictures received")
        for (userId, marker) in _friendManager.userMarkers {
            setMarkerImage(marker, userId: userId)
        }
    }
    
    func friendLocationsUpdated(friendData: [PFObject]) {
        //display locations
        print("friends location updated")
        //make array of markers if first time
        //display them
        for data in friendData {
            let location = data.objectForKey(parse_frienddata_location) as? PFGeoPoint
            if location != nil {
                //make marker to display location
                let user = data.objectForKey(parse_frienddata_user) as! PFObject
                if let marker = _friendManager.userMarkers[user.objectId!] {
                    marker.position = CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude)
                    marker.userData = user.objectId!
                    
                }
                else {
                    createNewMarker(user, location: location)
                }
                
                print("location: \(location!.latitude) \(location!.longitude)")
                
            }
        }
        _mapView!.myLocationEnabled = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        containerVC?.removeChildren()
    }
    
    //to fufill delegates
    func friendRequestSent() { }
    func friendRequestAccepted() { }
    func pendingFromRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func pendingToRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func facebookFriendsFound(facebookFriends: [PFUser]) { }
    func searchFinished(searchResults: [PFUser]) { }
    
}