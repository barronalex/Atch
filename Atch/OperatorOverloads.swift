//
//  OperatorOverloads.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse

func += (inout left: Dictionary<String, UIImage>, right: Dictionary<String, UIImage>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}

public func == (left: (PFObject), right: (PFObject)) -> Bool {
    if left.objectId! == right.objectId! {
        return true
    }
    return false
}

//func == (var left: [String], var right: [String]) -> Bool {
//    left.sort( {$0 > $1} )
//    right.sort( {$0 > $1} )
//    if left == right { return true }
//    return false
//}

extension PFObject: Equatable {}