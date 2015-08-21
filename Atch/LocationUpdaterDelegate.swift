//
//  LocationUpdaterDelegate.swift
//  Atch
//
//  Created by Alex Barron on 8/18/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import CoreLocation
import Parse

protocol LocationUpdaterDelegate {
    func locationUpdated(location: CLLocationCoordinate2D)
    func friendLocationsUpdated(friendData: [PFObject])
}
