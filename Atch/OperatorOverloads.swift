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

func == (let left: [String], let right: [String]) -> Bool {
    if left.count != right.count { return false }
    let leftSort = left.sort({ $0 < $1 })
    let rightSort = right.sort({ $0 < $1 })
    for var i = 0; i < left.count; i++ {
        if leftSort[i] != rightSort[i] {
            return false
        }
    }
    return true
}