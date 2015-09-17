//
//  Messages.swift
//  Atch
//
//  Created by Alex Barron on 9/15/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreData
import Parse

class Message: NSManagedObject {

    @NSManaged var messageText: String
    
    @NSManaged var messageUser: String
    
    @NSManaged var userIds: String
    
    @NSManaged var createdAt: NSDate
    
    @NSManaged var df: String?
    
    @NSManaged var objectId: String


    
    func initialise(parseMessage: PFObject, userIds: String) {
        messageText = parseMessage.objectForKey("messageText") as! String
        messageUser = (parseMessage.objectForKey("fromUser") as! PFUser).objectId!
        self.userIds = userIds
        self.createdAt = parseMessage.createdAt!
        self.objectId = parseMessage.objectId!
        if let df = parseMessage.objectForKey("decorationFlag") as? String {
            self.df = df
        }
    }
    
    func getParseObject() -> PFObject {
        let parseObject = PFObject(className: "Message")
        parseObject.setObject(self.messageText, forKey: "messageText")
        let user = PFUser(withoutDataWithObjectId: messageUser)
        parseObject.setObject(user, forKey: "fromUser")
        parseObject.setObject(createdAt, forKey: "createdAt")
        if df != nil {
            parseObject.setObject(df!, forKey: "decorationFlag")
        }
        parseObject.objectId = self.objectId
        return parseObject
    }


}
