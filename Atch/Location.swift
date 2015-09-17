//
//  Location.swift
//  Atch
//
//  Created by Alex Barron on 8/24/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import GoogleMaps

var _locationUpdater = LocationUpdater()

var _mapView: GMSMapView?

let stanfordCam = GMSCameraPosition(target: CLLocationCoordinate2D(latitude: 37.43, longitude: -122.17), zoom: Float(14), bearing: 0, viewingAngle: 0)
