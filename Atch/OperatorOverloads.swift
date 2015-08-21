//
//  OperatorOverloads.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

func += (inout left: Dictionary<String, UIImage>, right: Dictionary<String, UIImage>) {
    for (k, v) in right {
        left.updateValue(v, forKey: k)
    }
}