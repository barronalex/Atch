//
//  Messenger.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse

class Messenger {
    
    var delegate: MessengerDelegate?
    var messageHistory: PFObject?
    
    func sendMessage(messageText: String) {
        if self.messageHistory != nil {
            println("sent message")
            PFCloud.callFunctionInBackground("sendMessage", withParameters: ["messageHistoryId":messageHistory!.objectId!, "messageText":messageText]) {
                (response: AnyObject?, error: NSError?) -> Void in
                self.delegate?.sentMessage()
            }
        }
        else {
            self.delegate?.sentMessage()
        }
        
        
        
    }
    
    func getNewMessagesFrom(user: PFUser) {
        
    }
    
    
    func getMessageHistoryFrom(userIds: [String]) {
        PFCloud.callFunctionInBackground("getOrCreateMessageHistory", withParameters: ["userIds":userIds]) {
            (response: AnyObject?, error: NSError?) -> Void in
            if error != nil {
                println("\(error)")
            }
            println("made it")
            if let messageHistory = response as? PFObject {
                self.messageHistory = messageHistory
                self.getMessagesFromHistory()
                let name = messageHistory.objectForKey("name") as! String
                println("mh name: \(name)")
            }
        }
    }
    
    func getMessagesFromHistory() {
        if self.messageHistory != nil {
            //if there are messages
            if let messageList = messageHistory!.objectForKey("messageList") as? [String] {
                var messageQuery = PFQuery(className: "Message")
                messageQuery.whereKey("objectId", containedIn: messageList)
                messageQuery.orderByAscending("createdAt")
                messageQuery.findObjectsInBackgroundWithBlock {
                    (messages: [AnyObject]?, error: NSError?) -> Void in
                    
                    if error == nil {
                        if let messages = messages as? [PFObject] {
                            self.delegate?.gotPreviousMessages(messages)
                        }
                    } else {
                        print("error in messages request")
                        
                    }
                }
                
            }
            else {
                self.delegate?.gotPreviousMessages([PFObject]())
            }
        }
        else {
            self.delegate?.gotPreviousMessages([PFObject]())
        }
    }
    
    
    
}
