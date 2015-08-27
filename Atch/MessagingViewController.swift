//
//  MessagingViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import Parse

class MessagingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, MessengerDelegate {
    //includes current user
    var toUsers = [String]()
    var messages = [PFObject]()
    var messenger = Messenger()
    //have a map of messageids to height
    var messageHeights = [String:CGFloat]()
    
    let messageSpacing: CGFloat = 20
    let labelWidth: CGFloat = 115
    
    @IBOutlet weak var messageTable: UITableView!
    
    @IBOutlet weak var textViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func sendButtonTapped() {
        //self.messageTextView.endEditing(true)
        //self.messageTextView.enabled = false
        self.sendButton.enabled = false
        messenger.sendMessage(messageTextView.text)
    }
    
    
    
    func resizeTextView() {
        let prevHeight = messageTextView.frame.height
        let sizeThatFitsContent = messageTextView.sizeThatFits(messageTextView.frame.size)
        textViewConstraint.constant = sizeThatFitsContent.height
        dockViewHeightConstraint.constant += (sizeThatFitsContent.height - prevHeight)
        println("change: \(sizeThatFitsContent.height - prevHeight)")
        let offset = sizeThatFitsContent.height - prevHeight
        println("offset: \(offset)")
        self.messageTable.contentOffset.y += offset
    }
    
    func textViewDidChange(textView: UITextView) {
        resizeTextView()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = kbRect.size.height - currentKeyboardHeight
        currentKeyboardHeight = kbRect.size.height
        moveKeyboardUpBy(delta, animationTime: animationTime)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = -kbRect.height
        currentKeyboardHeight = 0
        println("keyboard hiding: \(kbRect.height)")
        moveKeyboardUpBy(delta, animationTime: animationTime)
    }
    
    func moveKeyboardUpBy(delta: CGFloat, animationTime: NSNumber) {
        self.view.layoutIfNeeded()
        println("DELTA: \(delta)")
        if delta == 0 {
            return
        }
        UIView.animateWithDuration(NSTimeInterval(animationTime), animations: {
            self.dockViewHeightConstraint.constant += delta
            self.messageTable.contentOffset.y += delta
            self.view.layoutIfNeeded()
            
        }, completion: nil)
    }
    
    func tableViewTapped() {
        self.messageTextView.endEditing(true)
    }
    
    @IBOutlet weak var dockViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidDisappear(animated: Bool) {
        println("removing observers")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let prevHeight = messageTextView.frame.height
        let sizeThatFitsContent = messageTextView.sizeThatFits(messageTextView.frame.size)
        textViewConstraint.constant = sizeThatFitsContent.height
        dockViewHeightConstraint.constant += (sizeThatFitsContent.height - prevHeight)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("messageReceived:"), name: messageNotificationReceivedKey, object: nil)
        println("adding observers")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        println("toUsers: \(toUsers)")
        //self.messageTable.rowHeight = UITableViewAutomaticDimension
        self.messageTable.delegate = self
        self.messageTable.dataSource = self
        self.messageTextView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        self.messageTable.addGestureRecognizer(tapGesture)
        self.messenger.delegate = self
        self.messenger.getMessageHistoryFrom(toUsers)
        
    }
    
    func getHeightOfLabel(text: String) -> CGFloat {
        var sizeGettingLabel = UILabel()
        sizeGettingLabel.font = UIFont.systemFontOfSize(17)
        sizeGettingLabel.text = text
        sizeGettingLabel.numberOfLines = 0
        sizeGettingLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        let maxSize = CGSizeMake(self.view.frame.width - labelWidth, 9999)
        let expectedSize = sizeGettingLabel.sizeThatFits(maxSize)
        return expectedSize.height
    }

}

//Table View Methods
extension MessagingViewController {
    
    func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [AnyObject]? {
        let message = messages[indexPath.row]
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        let time = message.createdAt!
        
        let timeString = formatter.stringFromDate(time)
        println("time: \(timeString)")
        let timeStamp = UITableViewRowAction(style: .Normal, title: timeString) { action, index in
        }
        timeStamp.backgroundColor = UIColor.whiteColor()
        UIButton.appearance().setTitleColor(UIColor.blackColor(), forState: .Normal)
        return [timeStamp]
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let message = messages[indexPath.row]
        let text = message.objectForKey(parse_message_text) as! String
        let textHeight = getHeightOfLabel(text) + messageSpacing
        return textHeight
        
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
        // Most of the time my data source is an array of something...  will replace with the actual name of the data source
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let message = messages[indexPath.row]
        let messageUser = message.objectForKey(parse_message_fromUser) as! PFUser
        if messageUser.objectId == PFUser.currentUser()!.objectId {
            let cell = messageTable.dequeueReusableCellWithIdentifier("MessageCell") as! MessageCell
            cell.messageText.text = message.objectForKey(parse_message_text) as? String
            if messageHeights[message.objectId!] == nil {
                messageHeights[message.objectId!] = cell.messageText.frame.height
            }
            println("CELL HEIGHT: \(cell.frame.height)")
            return cell
        }
        else {
            let cell = messageTable.dequeueReusableCellWithIdentifier("IncomingMessageCell") as! MessageCell
            cell.messageText.text = message.objectForKey(parse_message_text) as? String
            if messageHeights[message.objectId!] == nil {
                messageHeights[message.objectId!] = cell.messageText.frame.height
            }
            println("CELL HEIGHT: \(cell.frame.height)")
            return cell
        }
    }
}

//Messenger Methods
extension MessagingViewController {
    
    func sentMessage() {
        println("method finished")
        messenger.getMessageHistoryFrom(toUsers)
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTextView.text = ""
            self.resizeTextView()
            //self.messageTextField.enabled = true
            self.sendButton.enabled = true
        }
    }
    
    func refreshMessages() {
        messenger.getMessageHistoryFrom(toUsers)
        println("refreshing")
    }
    
    func gotPreviousMessages(messages: [PFObject]) {
        //display messages
        println("got messages")
        println("message count: \(messages.count)")
        self.messages = messages
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTable.reloadData()
            self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
            println("to bottom")
        }
    }
    
    func messageReceived(notification: NSNotification) {
        println("message received")
        let userInfo = notification.userInfo
        if userInfo != nil {
            if let toUsers = userInfo!["toUsers"] as? [String] {
                self.toUsers = toUsers
            }
        }
        self.refreshMessages()
    }

}
