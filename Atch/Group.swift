//
//  Group.swift
//  Atch
//
//  Created by Alex Barron on 8/29/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreLocation
import GoogleMaps

let distanceToBeInGroupMetres: CLLocationDistance = 100

class Group {
    
    var toUsers = [String]()
    var position: CLLocation?
    var marker: GMSMarker?
    var image: UIImage?
    
    
    init(toUsers: [String], position: CLLocation) {
        self.toUsers = toUsers
        self.position = position
    }
    
    static func generateHashStringFromArray(toUsers: [String]) -> String {
        let sortedUsers = toUsers.sort( {$0 < $1} )
        print("sortedUsers: \(sortedUsers)")
        var hash = ""
        for var i = 0; i < sortedUsers.count; i++ {
            hash += sortedUsers[i]
        }
        print("hash: \(hash)")
        return hash

    }
    
    func getHashString() -> String {
        //make string of toUser ids in lexographical order
        print("toUsers: \(toUsers)")
        let sortedUsers = toUsers.sort( {$0 < $1} )
        print("sortedUsers: \(sortedUsers)")
        var hash = ""
        for var i = 0; i < sortedUsers.count; i++ {
            hash += sortedUsers[i]
        }
        print("hash: \(hash)")
        return hash
    }
    
    
    static func mergeGroups(var groups: [Group]) -> [Group] {
        for var i = 0; i < groups.count; i++ {
            for var j = i + 1; j < groups.count; j++ {
                if compareGroups(groups[i], group2: groups[j]) {
                    let mergedGroup = mergeGroups(groups[i], group2: groups[j])
                    groups[i] = mergedGroup
                    groups.removeAtIndex(j)
                    return mergeGroups(groups)
                }
            }
        }
        return groups

    }
    //index i of users corresponds to index i of locations
    static func findGroups(users: [String]) -> [Group] {
        var groups = [Group]()
        
        //initialise groups
        for var i = 0; i < users.count; i++ {
            let group = Group(toUsers: [users[i]], position: _friendManager.userMap[users[i]]!.location!)
            groups.append(group)
        }
        print("groups: \(groups.count)")
        let result = mergeGroups(groups)
        for group in result {
            //only make the image if it doesn't already exist
            
            group.image = ImageProcessor.createImageFromGroup(group)
            _friendManager.groupMap[group.getHashString()] = group
        }
        _friendManager.groups = result
        //add groups to map
        return result
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
            if groups[i].toUsers.contains(user) {
                return i
            }
        }
        //should never happen
        print("Houston, we have a problem")
        return -1
    }
    
    
    static func compareGroups(group1: Group, group2: Group) -> Bool {
        for var i = 0; i < group1.toUsers.count; i++ {
            for var j = 0; j < group2.toUsers.count; j++ {
                //if any of the sets of two users are close enough
                if compareLocations(_friendManager.userMap[group1.toUsers[i]]!.location!, loc2: _friendManager.userMap[group2.toUsers[j]]!.location!) {
                    return true
                }
                
            }
        }
        return false
    }
    
    static func compareLocations(loc1: CLLocation, loc2: CLLocation) -> Bool {
        let dist = loc1.distanceFromLocation(loc2)
        if dist < distanceToBeInGroupMetres {
            return true
        }
        return false
    }

    
}