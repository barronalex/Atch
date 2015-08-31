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
import CoreData

class AtchMapViewController: UIViewController, LocationUpdaterDelegate, FriendManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet var bannerGesture: UIPanGestureRecognizer!
    
    @IBOutlet weak var bannerLabel: UILabel!
    
    @IBOutlet weak var bannerView: UIView!
    
    @IBOutlet weak var bannerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var topContainerConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var bannerConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var friendsButton: UIButton!
    
    @IBOutlet weak var logout: UIButton!
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    
    var mapTapGesture: UITapGestureRecognizer?
    var containerVC: MapContainerViewController?
    var firstLocation = true
    var camera: GMSCameraPosition?
    var tappedUserId: String?
    var bannerUp = false
    var bannerAtTop = false
    
    let zeroMapInsets = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0)
    let bannerMapInsets = UIEdgeInsetsMake(0.0, 0.0, 110, 0.0)
    let upwardsMapCorrection: CGFloat = 110
    let downwardsMapCorrection: CGFloat = 110
    let topMargin: CGFloat = 20
    let bannerAppearAnimationTime = 0.3
    let bannerHeightAtTop: CGFloat = 100
    let bannerHeightAtBottom: CGFloat = 110
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        println("loading Atch")
        //friendsButton.setImage(UIImage(named: "circle.png"), forState: .Highlighted)
        setShadows()
        self.containerHeightConstraint.constant = self.view.frame.height - self.bannerHeightAtBottom
        self.view.layoutIfNeeded()
        self.topContainerConstraint.constant = self.view.frame.height - 20
        self.view.layoutIfNeeded()
        let tapGesture = UITapGestureRecognizer(target: self, action: "bannerTapped")
        self.bannerView.addGestureRecognizer(tapGesture)
        setUpLocationManager()
        setUpMap()
        setUpFriendManager()
        
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
        if segue.identifier == "maptofriends" {
            _mapView?.padding = self.zeroMapInsets
        }
    }
    
    func setShadows() {
        logout.layer.shadowColor = UIColor.grayColor().CGColor
        logout.layer.shadowOffset = CGSizeMake(1, 1)
        logout.layer.shadowRadius = 1
        logout.layer.shadowOpacity = 1.0
        friendsButton.layer.shadowColor = UIColor.grayColor().CGColor
        friendsButton.layer.shadowOffset = CGSizeMake(1, 1)
        friendsButton.layer.shadowRadius = 1
        friendsButton.layer.shadowOpacity = 1.0
        bannerView.layer.shadowColor = UIColor.grayColor().CGColor
        bannerView.layer.shadowOffset = CGSizeMake(1, 1)
        bannerView.layer.shadowRadius = 1
        bannerView.layer.shadowOpacity = 1.0
    }

    @IBAction func hereButton() {
        let childVCs = containerVC?.childVCs
        if let childVCs = childVCs {
            let messageVC = childVCs[0] as! MessagingViewController
            messageVC.messenger.sendMessage("meet here", decorationFlag:"h")
        }
    }
    
    @IBAction func thereButton() {
        let childVCs = containerVC?.childVCs
        if let childVCs = childVCs {
            let messageVC = childVCs[0] as? MessagingViewController
            messageVC?.messenger.sendMessage("meet there", decorationFlag:"t")
        }
    }
}

//#MARK: Initialisation Methods
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
    
    private func setUpLocationManager() {
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
    
    private func setUpMap() {
//        if let location = _locationUpdater!.getLocation() {
//            if _mapView == nil {
//                _mapView = GMSMapView.mapWithFrame(CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height), camera: GMSCameraPosition.cameraWithTarget(location.coordinate, zoom: 6))
//            }
//            _locationUpdater?.sendLocationToServer()
//            _locationUpdater?.getFriendLocationsFromServer()
//            _mapView!.myLocationEnabled = true
//            firstLocation = false
//            
//        }
//        else {
        if _mapView == nil {
                _mapView = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
        }
        self.view.addSubview(_mapView!)
        _mapView!.settings.myLocationButton = true
        //self.view.bringSubviewToFront(circleImageLeft)
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

//#MARK: Banner Methods
extension AtchMapViewController {
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            bannerTapped()
            return
        }
        if recognizer.state == UIGestureRecognizerState.Began && bannerAtTop {
            self.bannerHeightConstraint.constant = self.bannerHeightAtBottom
            self.view.endEditing(true)
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
        println("banner tapped")
        if !bannerAtTop {
            UIView.animateWithDuration(NSTimeInterval(0.4), animations: {
                _mapView?.padding = self.bannerMapInsets
                self.topContainerConstraint.constant = self.bannerView.frame.height - self.topMargin - (self.bannerHeightAtBottom - self.bannerHeightAtTop)
                
                self.bannerConstraint.constant = self.view.frame.height - self.bannerView.frame.height + (self.bannerHeightAtBottom - self.bannerHeightAtTop)
                println("bannerConstraint: \(self.bannerConstraint.constant)")
                println("banner height: \(self.bannerHeightAtTop)")
                self.bannerHeightConstraint.constant = self.bannerHeightAtTop
                self.containerHeightConstraint.constant = self.view.frame.height - self.bannerHeightAtTop
                self.view.layoutIfNeeded()
                })
            bannerAtTop = true
        }
        else {
            lowerBanner()
        }
        println("banner height real: \(bannerView.frame.height)")
    }
    
    func lowerBanner() {
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(bannerAppearAnimationTime), animations: {
            self.bannerConstraint.constant = 0
            self.topContainerConstraint.constant = self.view.frame.height - 20
            _mapView?.padding = self.bannerMapInsets
            self.bannerHeightConstraint.constant = self.bannerHeightAtBottom
            self.containerHeightConstraint.constant -= (self.bannerHeightAtBottom - self.bannerHeightAtTop)
            self.view.layoutIfNeeded()
            })
        bannerAtTop = false
        self.view.endEditing(true)
    }
    
    func putBannerUp() {
        var toUsers = [tappedUserId!, PFUser.currentUser()!.objectId!]
        containerVC?.goToMessages(toUsers)
        let colour = _friendManager.userMap[tappedUserId!]?.colour
        bannerView.backgroundColor = colour
        //put up banner
        println("friend map count: \(_friendManager.friends.count)")
        println("tapped id: \(tappedUserId)")
        bannerLabel.text = _friendManager.userMap[self.tappedUserId!]?.parseObject?.objectForKey("firstname") as? String
        println("BANNER TEXT: \(bannerLabel.text)")
        if bannerLabel.text == nil {
           bannerLabel.text = _friendManager.userMap[self.tappedUserId!]?.parseObject?.objectForKey(parse_user_username) as? String
        }
        self.view.bringSubviewToFront(bannerView)
        self.view.bringSubviewToFront(containerView)
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(bannerAppearAnimationTime), animations: {
            self.bannerConstraint.constant = 0
            _mapView?.padding = self.bannerMapInsets
            self.view.layoutIfNeeded()
        })
        bannerUp = true
    }
    
    func switchBanners() {
        self.view.endEditing(true)
        self.containerVC?.removeChildren()
        var toUsers = [tappedUserId!, PFUser.currentUser()!.objectId!]
        containerVC?.goToMessages(toUsers)
        let colour = _friendManager.userMap[tappedUserId!]?.colour
        bannerView.backgroundColor = colour
        //put up banner
        println("friend map count: \(_friendManager.friends.count)")
        println("tapped id: \(tappedUserId)")
        
        bannerLabel.text = _friendManager.userMap[self.tappedUserId!]?.parseObject?.objectForKey(parse_user_username) as? String
        if bannerLabel.text == nil {
            bannerLabel.text = _friendManager.userMap[self.tappedUserId!]?.parseObject?.objectForKey(parse_user_username) as? String
        }

    }
    
    func putBannerDown() {
        self.view.endEditing(true)
        
        UIView.animateWithDuration(NSTimeInterval(0.4), animations: {
            self.topContainerConstraint.constant = self.view.frame.height - 20
            self.bannerConstraint.constant = -self.bannerView.frame.height
            _mapView?.padding = self.zeroMapInsets
            self.bannerHeightConstraint.constant = self.bannerHeightAtBottom
            self.containerHeightConstraint.constant -= (self.bannerHeightAtBottom - self.bannerHeightAtTop)
            self.view.layoutIfNeeded()
            }, completion: {
                (finished) in
                self.containerVC?.removeChildren()
        })
        bannerUp = false
        bannerAtTop = false
    }
    
    func bringUpMessagesScreen() {
        putBannerUp()
        bannerAtTop = false
        bannerTapped()
    }

}

//#MARK: Map Methods
extension AtchMapViewController {
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        println("tapped marker")
        tappedUserId = (marker.userData as! Group).toUsers[0]
        println("marker user id: \(tappedUserId!)")
        if bannerUp {
            switchBanners()
        }
        else {
            putBannerUp()
        }
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
    
    private func setMarkerImage(marker: GMSMarker) {
//        if let image = _friendManager.friendPics[userId] {
//            marker.icon = image
//            let colour = _friendManager.userMap[userId]?.colour
//            marker.icon = ImageProcessor.createCircle(image, borderColour: colour!, markerSize: true)
//            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
//        }
        
        if let image = (marker.userData as? Group)?.image {
            marker.icon = image
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
        }
        
    }
    
    private func createNewMarker(group: Group) {
        let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: group.position!.coordinate.latitude, longitude: group.position!.coordinate.longitude))
        marker.map = _mapView
        for user in group.toUsers {
            _friendManager.userMap[user]?.marker = marker
            _friendManager.userMap[user]?.group = group
        }
        marker.userData = group
        setMarkerImage(marker)
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

//#MARK: Friend Methods
extension AtchMapViewController {
    
    func friendListFound(friends: [PFUser]) {
        //map user ids to user objects
        FacebookManager.downloadProfilePictures(friends)
        if self.tappedUserId != nil {
            bannerLabel.text = _friendManager.userMap[self.tappedUserId!]?.parseObject?.objectForKey(parse_user_username) as? String
            println("BANNER TEXT POST FRIENDS: \(bannerLabel.text)")
            if bannerLabel.text == nil {
                bannerLabel.text = _friendManager.userMap[self.tappedUserId!]?.parseObject?.objectForKey(parse_user_username) as? String
            }
        }
        _locationUpdater?.getFriendLocationsFromServer()
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("pictures received")
        _locationUpdater?.getFriendLocationsFromServer()
    }
    
    func friendLocationsUpdated(friendData: [PFObject]) {
        //display locations
        print("friends location updated")
        //make array of markers if first time
        //display them
        if _friendManager.friends.count == 0 {
            return
        }
        var users = [String]()
        for data in friendData {
            if let location = data.objectForKey(parse_frienddata_location) as? PFGeoPoint {
                if let user = data.objectForKey(parse_frienddata_user) as? PFObject {
                    let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    if _friendManager.userMap[user.objectId!] != nil {
                        _friendManager.userMap[user.objectId!]!.location = clLocation
                        users.append(user.objectId!)
                    }
                }
            }
        }
        let groups = Group.findGroups(users)
        //once the groups are found send them to the friends vc
        NSNotificationCenter.defaultCenter().postNotificationName(groupsFoundNotificationKey, object: nil)
        _mapView!.clear()
        for group in groups {
            println("Group members: \(group.toUsers)")
            //create a new marker and remove all old ones
            createNewMarker(group)
        }
        
//            if location != nil {
//                //make marker to display location
//                
//                if let marker = _friendManager.userMarkers[user.objectId!] {
//                    marker.position = CLLocationCoordinate2D(latitude: location!.latitude, longitude: location!.longitude)
//                    marker.userData = user.objectId!
//                    if marker.icon == nil {
//                        setMarkerImage(marker, userId: user.objectId!)
//                    }
//                    
//                }
//                else {
//                    createNewMarker(user, location: location)
//                }
//                
//                print("location: \(location!.latitude) \(location!.longitude)")
//                
//            }
//        }
        _mapView!.myLocationEnabled = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        containerVC?.removeChildren()
    }
    
    //to fufill delegates
    func friendRequestSent(req: PFObject, userId: String) { }
    func friendRequestAccepted() { }
    func pendingFromRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func pendingToRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func facebookFriendsFound(facebookFriends: [PFUser]) { }
    func searchFinished(searchResults: [PFUser]) { }
    
}