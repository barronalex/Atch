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

let closeZoomLevel: Float = 16

class AtchMapViewController: UIViewController, LocationUpdaterDelegate, FriendManagerDelegate, GMSMapViewDelegate {
    
    @IBOutlet var bannerGesture: UIPanGestureRecognizer!
    
    @IBOutlet weak var bannerLabel: UILabel!
    
    @IBOutlet weak var bannerImage: UIImageView!
    
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
    var tappedUserIds = [String]()
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
            
            destVC.toUsers = tappedUserIds
        }
        if segue.identifier == "logoutfrommap" {
            println("logging out from map")
            putBannerDown()
            _mapView?.myLocationEnabled = false
            _mapView?.settings.myLocationButton = false
            _locationUpdater.stopUpdates()
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
            messageVC.messenger.sendMessage("meet here", decorationFlag:"h", goToBottom: true)
        }
    }
    
    @IBAction func thereButton() {
        let childVCs = containerVC?.childVCs
        if let childVCs = childVCs {
            let messageVC = childVCs[0] as? MessagingViewController
            messageVC?.messenger.sendMessage("meet there", decorationFlag:"t", goToBottom: true)
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
        if !_friendManager.downloadedPics {
            println("downloading shit")
            FacebookManager.downloadProfilePictures(_friendManager.friends)
        }
    }
    
    private func setUpLocationManager() {
        if !_locationUpdater.updating {
            _locationUpdater.startUpdates()
        }
         _locationUpdater.delegate = self
        
    }
    
    func mapView(mapView: GMSMapView!, didTapAtCoordinate coordinate: CLLocationCoordinate2D) {
        if bannerUp {
            putBannerDown()
        }
    }
    
    private func setUpMap() {

        if _mapView == nil {
            _mapView = GMSMapView(frame: CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height))
            _mapView!.settings.rotateGestures = false
            _mapView!.camera = stanfordCam
        }
        self.view.addSubview(_mapView!)
        _mapView!.settings.myLocationButton = true
        self.view.bringSubviewToFront(friendsButton)
        self.view.bringSubviewToFront(logout)
        _mapView?.delegate = self
        _locationUpdater.getFriendLocationsFromServer()
        //addMarkers()
    }
}


//#MARK: Map Methods
extension AtchMapViewController {
    
    func mapView(mapView: GMSMapView!, didTapMarker marker: GMSMarker!) -> Bool {
        println("tapped marker")
        if tappedUserIds == (marker.userData as! Group).toUsers {
            //zoom in
            _mapView!.animateToCameraPosition(GMSCameraPosition.cameraWithTarget(marker.position, zoom: closeZoomLevel))
            return true
        }
        tappedUserIds = (marker.userData as! Group).toUsers
        println("marker user id: \(tappedUserIds)")
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
        if let image = (marker.userData as? Group)?.image {
            marker.icon = image
            marker.groundAnchor = CGPoint(x: 0.5, y: 0.5)
            marker.map = _mapView
        }
    }
    
    private func createNewMarker(group: Group) {
        let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: group.position!.coordinate.latitude, longitude: group.position!.coordinate.longitude))
        for user in group.toUsers {
            _friendManager.userMap[user]?.marker = marker
            _friendManager.userMap[user]?.group = group
        }
        marker.userData = group
        setMarkerImage(marker)
    }
    
    func locationUpdated(location: CLLocationCoordinate2D) {
        print("location updated")
        if firstLocation {
            println("first location")
            PFCloud.callFunctionInBackground("sendLoginNotifications", withParameters: nil)
            _locationUpdater.sendLocationToServer()
            friendLocationsUpdated(_friendManager.lastFriendData)
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
        if tappedUserIds.count > 0 {
            setBannerColour()
            setBannerText()
        }
        friendLocationsUpdated(_friendManager.lastFriendData)
    }
    
    func friendProfilePicturesReceived(notification: NSNotification) {
        println("pictures received")
        _locationUpdater.getFriendLocationsFromServer()
        _friendManager.downloadedPics = true
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
        println("Num friends: \(_friendManager.friends.count)")
        println("Num friend data: \(friendData.count)")
        for data in friendData {
            if let user = data.objectForKey(parse_frienddata_user) as? PFObject {
                if let location = data.objectForKey(parse_frienddata_location) as? PFGeoPoint {
                    println("location: \(location)")
                    let clLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
                    if _friendManager.userMap[user.objectId!] != nil {
                        _friendManager.userMap[user.objectId!]!.location = clLocation
                        users.append(user.objectId!)
                    }
                    _friendManager.userMap[user.objectId!]?.online = true
                }
                else {
                    println("OFFLINE")
                    _friendManager.userMap[user.objectId!]?.online = false
                }
            }
            
        }
        NSNotificationCenter.defaultCenter().postNotificationName(friendDataReceivedNotificationKey, object: nil)
        let groups = Group.findGroups(users)
        //once the groups are found send them to the friends vc
        NSNotificationCenter.defaultCenter().postNotificationName(groupsFoundNotificationKey, object: nil)
        _mapView!.clear()
        for group in groups {
            println("Group members: \(group.toUsers)")
            //create a new marker and remove all old ones
            createNewMarker(group)
        }

        _mapView!.myLocationEnabled = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        containerVC?.removeChildren()
        NSNotificationCenter.defaultCenter().removeObserver(self, name: profilePictureNotificationKey, object: nil)
    }
    
    //to fufill delegates
    func friendRequestSent(req: PFObject, userId: String) { }
    func friendRequestAccepted() { }
    func pendingFromRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func pendingToRequestsFound(requests: [PFObject], users: [PFUser]) { }
    func facebookFriendsFound(facebookFriends: [PFUser]) { }
    func searchFinished(searchResults: [PFUser]) { }
    
}