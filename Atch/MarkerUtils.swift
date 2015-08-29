//
//  MarkerUtils.swift
//  Atch
//
//  Created by Alex Barron on 8/29/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreLocation

class MarkerUtils {
    
    //index i of users corresponds to index i of locations
    static func findGroups(users: [String], locations: [CLLocation]) -> [Group] {
        var groups = [Group]()
        //initialise groups
        for var i = 0; i < users.count; i++ {
            let group = Group(toUsers: [users[i]], position: locations[i])
            groups.append(group)
        }
        for var i = 0; i < users.count; i++ {
            for var j = i + 1; j < users.count; j++ {
                if MarkerUtils.compareLocations(locations[i], loc2: locations[j]) {
                    let firstIndex = findGroupOfUserIndex(groups, user: users[i])
                    let secondIndex = findGroupOfUserIndex(groups, user: users[j])
                    if firstIndex != secondIndex {
                        let mergedGroup = mergeGroups(groups[firstIndex], group2: groups[secondIndex])
                        //place first group
                        groups[i] = mergedGroup
                        //remove second group
                        groups.removeAtIndex(j)
                    }
                }
            }
        }
        return groups
    }
    
    static func mergeGroups(group1: Group, group2: Group) -> Group {
        group1.toUsers += group2.toUsers
        let latitude = (group1.position!.coordinate.latitude + group2.position!.coordinate.latitude)/2
        let longitude = (group1.position!.coordinate.longitude + group2.position!.coordinate.longitude)/2
        let position = CLLocation(latitude: latitude, longitude: longitude)
        group1.position = position
        return group1
    }
    
    static func findGroupOfUserIndex(groups: [Group], user: String) -> Int {
        
        for var i = 0; i < groups.count; i++ {
            if contains(groups[i].toUsers, user) {
                return i
            }
        }
        //should never happen
        println("Houston, we have a problem")
        return -1
    }
    
    
    static func compareLocations(loc1: CLLocation, loc2: CLLocation) -> Bool {
        let dist = loc1.distanceFromLocation(loc2)
        if dist < 30 {
            return true
        }
        return false
    }
    
}