//
//  MessengerDelegate.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse

protocol MessengerDelegate {
    
    func sentMessage(goToBottom: Bool)
    
    func gotPreviousMessages(messages: [PFObject], toBottom: Bool)
    
}