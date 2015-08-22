//
//  UsernameManagerDelegate.swift
//  Atch
//
//  Created by Alex Barron on 8/15/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

protocol UsernameManagerDelegate {
    
    func getUsername()
    
    func usernameChosen()
    
    func finished()
    
    func nameInvalid()
}