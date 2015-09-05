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
    var updating = false
    var curLocation: CLLocation?
    var friendData: PFObject?
    var delegate: LocationUpdaterDelegate?
    var sendTimer: NSTimer?
    var getTimer: NSTimer?
    var locationTimer: NSTimer?
    
    func startUpdates() {
        print("start updates")
        let query = PFQuery(className: "FriendData")
        query.whereKey(parse_frienddata_user, equalTo: PFUser.currentUser()!)
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
            updating = true
        }
        NSTimer.scheduledTimerWithTimeInterval(1200, target: self, selector: Selector("stopUpdates"), userInfo: nil, repeats: false)
        sendTimer = NSTimer.scheduledTimerWithTimeInterval(60, target: self, selector: Selector("sendLocationToServer"), userInfo: nil, repeats: true)
        getTimer = NSTimer.scheduledTimerWithTimeInterval(40, target: self, selector: Selector("getFriendLocationsFromServer"), userInfo: nil, repeats: true)
    }
    
    func stopUpdates() {
        println("stop updating")
        sendTimer?.invalidate()
        getTimer?.invalidate()
        locationTimer?.invalidate()
        locationManager.stopUpdatingLocation()
        updating = false
    }
    
    func getLocation() -> CLLocation? {
        println("\(locationManager.location)")
        return locationManager.location
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [AnyObject]) {
        print("location updated")
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
            friendData!.setObject(PFGeoPoint(location: curLocation), forKey: parse_frienddata_location)
            friendData!.saveInBackground()
        }
    }
    
    func getFriendLocationsFromServer() {
        let query = PFQuery(className: "FriendData")
        query.whereKey(parse_frienddata_user, notEqualTo: PFUser.currentUser()!)
        query.whereKeyExists(parse_frienddata_location)
        
        var date = NSDate(timeIntervalSinceNow: 0)
       // query.whereKey("updatedAt", greaterThan: date - NSTimeInterval.
        query.findObjectsInBackgroundWithBlock {
            (friends: [AnyObject]?, error: NSError?) -> Void in
            if let friends = friends as? [PFObject] {
                _friendManager.lastFriendData = friends
                self.delegate?.friendLocationsUpdated(friends)
            }
        }
    }
}