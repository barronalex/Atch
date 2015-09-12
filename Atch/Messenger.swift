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
    
    func trimSpaces(text: String) -> String {
        var nsText: NSString = text
        var trimmedText = nsText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        println("Trimmed text: \(trimmedText)")
        return trimmedText
    }
    
    func sendMessage(messageText: String, decorationFlag: String, goToBottom: Bool) {
        if self.messageHistory != nil {
            println("sent message")
            PFCloud.callFunctionInBackground("sendMessage", withParameters: ["messageHistoryId":messageHistory!.objectId!, "messageText":trimSpaces(messageText), "decorationFlag":decorationFlag]) {
                (response: AnyObject?, error: NSError?) -> Void in
                self.delegate?.sentMessage(goToBottom)
            }
        }
        else {
            self.delegate?.sentMessage(goToBottom)
        }
        
        
        
    }
    
    func getNewMessagesFrom(user: PFUser) {
        
    }
    
    
    func getMessageHistoryFrom(var userIds: [String], toBottom: Bool) {
        userIds.append(PFUser.currentUser()!.objectId!)
        PFCloud.callFunctionInBackground("getOrCreateMessageHistory", withParameters: ["userIds":userIds]) {
            (response: AnyObject?, error: NSError?) -> Void in
            if error != nil {
                println("\(error)")
            }
            println("made it")
            if let messageHistory = response as? PFObject {
                self.messageHistory = messageHistory
                self.getMessagesFromHistory(toBottom)
                let name = messageHistory.objectForKey("name") as! String
                println("mh name: \(name)")
            }
        }
    }
    
    func getMessagesFromHistory(toBottom: Bool) {
        if self.messageHistory != nil {
            //if there are messages
            if let messageList = messageHistory!.objectForKey(parse_messageHistory_list) as? [String] {
                var messageQuery = PFQuery(className: "Message")
                messageQuery.whereKey("objectId", containedIn: messageList)
                messageQuery.orderByDescending("createdAt")
                messageQuery.findObjectsInBackgroundWithBlock {
                    (messages: [AnyObject]?, error: NSError?) -> Void in
                    
                    if error == nil {
                        if let messages = messages as? [PFObject] {
                            var revMessages = reverse(messages)
                            self.delegate?.gotPreviousMessages(revMessages, toBottom: toBottom)
                        }
                    } else {
                        print("error in messages request")
                        
                    }
                }
                
            }
            else {
                self.delegate?.gotPreviousMessages([PFObject](), toBottom: false)
            }
        }
        else {
            self.delegate?.gotPreviousMessages([PFObject](), toBottom: false)
        }
    }
    
    
    
}
