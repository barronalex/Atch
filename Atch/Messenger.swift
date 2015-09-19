//
//  Messenger.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Parse
import CoreData

class Messenger {
    
    var delegate: MessengerDelegate?
    var messageHistory: PFObject?
    
    let managedObjectContext = (UIApplication.sharedApplication().delegate as! AppDelegate).managedObjectContext
    
    func sendMessage(messageText: String, decorationFlag: String, goToBottom: Bool) {
        if self.messageHistory != nil {
            print("sent message")
            PFCloud.callFunctionInBackground("sendMessage", withParameters: ["messageHistoryId":messageHistory!.objectId!, "messageText":messageText, "decorationFlag":decorationFlag]) {
                (response: AnyObject?, error: NSError?) -> Void in
                self.delegate?.sentMessage(goToBottom)
            }
        }
        else {
            self.delegate?.sentMessage(goToBottom)
        }
        
    }
    
    
    
    func getCachedMessages(var userIds: [String]) -> [PFObject] {
        var objects = [PFObject]()
        userIds.append(PFUser.currentUser()!.objectId!)
        let hashUserIds = Group.generateHashStringFromArray(userIds)
        let fetchRequest = NSFetchRequest(entityName: "Message")
        let predicate = NSPredicate(format: "userIds == %@", hashUserIds)
        fetchRequest.predicate = predicate
        if let fetchResults = try! managedObjectContext.executeFetchRequest(fetchRequest) as? [Message] {
            print("found messages")
            let sortedResults = fetchResults.sort {
               return $0.0.createdAt.compare($0.1.createdAt) == NSComparisonResult.OrderedAscending
            }
            for result in sortedResults {
                let parseObject = result.getParseObject()
                objects.append(parseObject)
            }
        }
        return objects
    }
    
    func getMessageHistoryFrom(var userIds: [String], toBottom: Bool) {
        userIds.append(PFUser.currentUser()!.objectId!)
        PFCloud.callFunctionInBackground("getOrCreateMessageHistory", withParameters: ["userIds":userIds]) {
            (response: AnyObject?, error: NSError?) -> Void in
            if error != nil {
                print("\(error)")
            }
            print("made it")
            if let messageHistory = response as? PFObject {
                self.messageHistory = messageHistory
                self.getMessagesFromHistory(toBottom, userIds: userIds)
                let name = messageHistory.objectForKey("name") as! String
                print("mh name: \(name)")
            }
        }
    }
    
    func storeMessages(messages: [PFObject], userIds: [String]) {
        print("store messages")
        let hashUserIds = Group.generateHashStringFromArray(userIds)
        let fetchRequest = NSFetchRequest(entityName: "Message")
        let predicate = NSPredicate(format: "userIds == %@", hashUserIds)
        fetchRequest.predicate = predicate
        if let fetchResults = try! managedObjectContext.executeFetchRequest(fetchRequest) as? [Message] {
            print("found messages")
            for result in fetchResults {
                managedObjectContext.deleteObject(result)
            }
            for message in messages {
                let newMessage = NSEntityDescription.insertNewObjectForEntityForName("Message", inManagedObjectContext: self.managedObjectContext) as! Message
                newMessage.initialise(message, userIds: hashUserIds)
            }
            try! managedObjectContext.save()
        }
    }
    
    func reverseArray(var arr: [AnyObject]) -> [AnyObject] {
        var firstIndex = 0
        var lastIndex = arr.count - 1
        while firstIndex < lastIndex {
            // swap
            let tmp = arr[firstIndex]
            arr[firstIndex] = arr[lastIndex]
            arr[lastIndex] = tmp
            
            // go to next pair
            firstIndex++
            lastIndex--
        }
        return arr
    }
    
    func getMessagesFromHistory(toBottom: Bool, userIds: [String]) {
        if self.messageHistory != nil {
            //if there are messages
            if let messageList = messageHistory!.objectForKey(parse_messageHistory_list) as? [String] {
                let messageQuery = PFQuery(className: "Message")
                messageQuery.whereKey("objectId", containedIn: messageList)
                messageQuery.orderByDescending("createdAt")
                messageQuery.findObjectsInBackgroundWithBlock {
                    (messages: [AnyObject]?, error: NSError?) -> Void in
                    
                    if error == nil {
                        if let messages = messages as? [PFObject] {
                            let revMessages = self.reverseArray(messages) as! [PFObject]
                            self.storeMessages(revMessages, userIds: userIds)
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
