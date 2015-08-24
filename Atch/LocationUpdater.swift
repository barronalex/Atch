//
//  LocationUpdater.swift
//  Atch
//
//  Created by Alex Barron on 8/18/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreLocation
import Parse

class LocationUpdater: NSObject, CLLocationManagerDelegate {
    
    var locationManager = CLLocationManager()
    var deferringUpdates = false
    var curLocation: CLLocation?
    var friendData: PFObject?
    var delegate: LocationUpdaterDelegate?
    var sendTimer: NSTimer?
    var getTimer: NSTimer?
    
    func startUpdates() {
        print("start updates")
        let query = PFQuery(className: "FriendData")
        query.whereKey("user", equalTo: PFUser.currentUser()!)
        query.getFirstObjectInBackgroundWithBlock {
            (data: AnyObject?, error: NSError?) -> Void in
            if let data = data as? PFObject {
                self.friendData = data
            }
        }
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        NSTimer.scheduledTimerWithTimeInterval(1200, target: self, selector: Selector("stopUpdates"), userInfo: nil, repeats: false)
        sendTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("sendLocationToServer"), userInfo: nil, repeats: true)
        getTimer = NSTimer.scheduledTimerWithTimeInterval(40, target: self, selector: Selector("getFriendLocationsFromServer"), userInfo: nil, repeats: true)
    }
    
    func stopUpdates() {
        println("stop updating")
        sendTimer?.invalidate()
        getTimer?.invalidate()
        locationManager.stopUpdatingLocation()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        curLocation = manager.location
        if !self.deferringUpdates && CLLocationManager.deferredLocationUpdatesAvailable() {
            print("started deferred updates")
            locationManager.allowDeferredLocationUpdatesUntilTraveled(CLLocationDistanceMax, timeout: 60)
            self.deferringUpdates = true
        }
        self.delegate?.locationUpdated(curLocation!.coordinate)
    }
    
    func locationManager(manager: CLLocationManager, didFinishDeferredUpdatesWithError error: NSError?) {
        print("finished with deferred updates")
        self.deferringUpdates = false
        sendLocationToServer()
    }
    
    func sendLocationToServer() {
        print("sending location to server")
        if friendData != nil {
            friendData!.setObject(PFGeoPoint(location: curLocation), forKey: "location")
            friendData!.saveInBackground()
        }
    }
    
    func getFriendLocationsFromServer() {
        let query = PFQuery(className: "FriendData")
        query.whereKey("user", notEqualTo: PFUser.currentUser()!)
        query.whereKeyExists("location")
        var date = NSDate(timeIntervalSinceNow: 0)
       // query.whereKey("updatedAt", greaterThan: date - NSTimeInterval.
        query.findObjectsInBackgroundWithBlock {
            (friends: [AnyObject]?, error: NSError?) -> Void in
            if let friends = friends as? [PFObject] {
                self.delegate?.friendLocationsUpdated(friends)
            }
        }
    }
    
    func goOnline() {
        
    }
}