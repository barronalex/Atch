//
//  MeetHereCell.swift
//  Atch
//
//  Created by Alex Barron on 9/11/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse

class MeetHereCell: UITableViewCell, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var responseTable: UITableView!
    
    var responses = [PFObject]()
    var responded = false
    var messageUser = ""
    var message = ""
    var df = ""
    var messenger = Messenger()
    
    let numberOfOptions = 2
    
    override func awakeFromNib() {
        super.awakeFromNib()
        responseTable?.delegate = self
        responseTable?.dataSource = self
        
    }
    
    static func getResponsesFromMessages(messages: [PFObject], row: Int) -> ([PFObject],Bool) {
        var responses = [PFObject]()
        var responded = false
        if let fromUser = messages[row].objectForKey("fromUser") as? PFUser {
            if fromUser.objectId! == PFUser.currentUser()!.objectId! {
                responded = true
            }
        }
        //look through messages to find responses to original message
        let originalMessage = messages[row]
        for var i = row + 1; i < messages.count; i++ {
            if let df = messages[i].objectForKey("decorationFlag") as? String {
                if df == "r" {
                    //check if object id matches
                    let messageText = messages[i].objectForKey("messageText") as! String
                    let messageId = split(messageText, maxSplit: 1, allowEmptySlices: true, isSeparator: { $0 == "_" })[0]
                    if messageId == messages[row].objectId {
                        println("Separated messageId: \(messageId)")
                        responses.append(messages[i])
                        if let fromUser = messages[i].objectForKey("fromUser") as? PFUser {
                            if fromUser.objectId! == PFUser.currentUser()!.objectId! {
                                responded = true
                            }
                        }
                    }
                    
                }
            }
        }
        println("responses: \(responses)")
        return (responses,responded)
    }
    
    func setUpTitleCell() -> UITableViewCell {
        let cell = responseTable.dequeueReusableCellWithIdentifier("Title") as! UITableViewCell
        if df == "h" {
            if messageUser == PFUser.currentUser()?.objectId {
                println("YOU WANT TO MEET HERE")
                cell.textLabel?.text = "You want to meet here"
                cell.backgroundColor = UIColor.whiteColor()
                cell.textLabel?.textColor = UIColor.blackColor()
            }
            else {
                println("OTHER WANT TO MEET HERE")
                if let name = _friendManager.userMap[messageUser]?.parseObject?.objectForKey("firstname") as? String {
                    cell.textLabel?.text = name + " wants to meet here"
                }
                if let colour = _friendManager.userMap[messageUser]?.colour {
                    cell.backgroundColor = colour
                    cell.textLabel?.textColor = UIColor.whiteColor()
                }
            }
        }
        else {
            if messageUser == PFUser.currentUser()?.objectId {
                println("YOU WANT TO MEET THERE")
                cell.textLabel?.text = "You want to meet there"
                cell.backgroundColor = UIColor.whiteColor()
                cell.textLabel?.textColor = UIColor.blackColor()
            }
            else {
                println("OTHER WANT TO MEET THERE")
                if let name = _friendManager.userMap[messageUser]?.parseObject?.objectForKey("firstname") as? String {
                    cell.textLabel?.text = name + " wants to meet there"
                }
                if let colour = _friendManager.userMap[messageUser]?.colour {
                    cell.backgroundColor = colour
                    cell.textLabel?.textColor = UIColor.whiteColor()
                }
            }
        }
        println("dequeuing title")
        return cell
    }
    
    func setUpResponseCell(indexPath: NSIndexPath) -> UITableViewCell {
        let cell = responseTable.dequeueReusableCellWithIdentifier("Response") as! UITableViewCell
        let fromUser = (responses[indexPath.row].objectForKey("fromUser") as! PFUser).objectId!
        println("fromUser: \(fromUser)")
        if let colour = _friendManager.userMap[fromUser]?.colour {
            cell.backgroundColor = colour
            cell.textLabel?.textColor = UIColor.whiteColor()
        }
        if let response = responses[indexPath.row].objectForKey("messageText") as? String {
            let reply = split(response, maxSplit: 1, allowEmptySlices: true, isSeparator: { $0 == "_" } )[1]
            if reply == "atch" {
                if let name = _friendManager.userMap[fromUser]?.parseObject?.objectForKey("firstname") as? String {
                    println("Atch")
                    cell.textLabel?.text = name + " is atch"
                }
                if fromUser == PFUser.currentUser()!.objectId! {
                    cell.textLabel?.text = "You're atch"
                    cell.backgroundColor = UIColor.whiteColor()
                    cell.textLabel?.textColor = UIColor.blackColor()
                }
            }
            else {
                if let name = _friendManager.userMap[fromUser]?.parseObject?.objectForKey("firstname") as? String {
                    println("Busy")
                    cell.textLabel?.text = name + " is busy"
                }
                if fromUser == PFUser.currentUser()!.objectId! {
                    cell.textLabel?.text = "You're busy"
                    cell.backgroundColor = UIColor.whiteColor()
                    cell.textLabel?.textColor = UIColor.blackColor()
                }
            }
        }
        println("dequeuing response")
        return cell
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.section == 0 && indexPath.row == 0 {
            return setUpTitleCell()
        }
        else if indexPath.section == 1 {
            return setUpResponseCell(indexPath)
        }
        else if indexPath.row == 1 {
            let cell = responseTable.dequeueReusableCellWithIdentifier("Response") as! UITableViewCell
            cell.backgroundColor = UIColor.blackColor()
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.textLabel?.text = "ATCH"
            return cell
        }
        else {
            let cell = responseTable.dequeueReusableCellWithIdentifier("Response") as! UITableViewCell
            cell.backgroundColor = UIColor.blackColor()
            cell.textLabel?.textColor = UIColor.whiteColor()
            cell.textLabel?.text = "busy"
            return cell
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            if responded {
                return 1
            }
            return numberOfOptions + 1
        }
        if responses.count > 0 {
            println("There are responses: \(responses.count)")
        }
        return responses.count
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        println("selected")
        if indexPath.section == 0 && indexPath.row == 1 {
            let messageText = message + "_atch"
            messenger.sendMessage(messageText, decorationFlag: "r", goToBottom: false)
        }
        if indexPath.section == 0 && indexPath.row == 2 {
            let messageText = message + "_busy"
            messenger.sendMessage(messageText, decorationFlag: "r", goToBottom: false)
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
}