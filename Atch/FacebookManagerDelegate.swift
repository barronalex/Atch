//
//  FacebookManagerDelegate.swift
//  Atch
//
//  Created by Alex Barron on 8/14/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

protocol FacebookManagerDelegate {
    
    func facebookLoginSucceeded()
    
    func facebookLoginFailed(reason: String)
    
    func goToSignUp()
    
    func parseLoginFailed()
    
    func parseLoginSucceeded()
    
    func alreadySignedUp()
    
}