//
//  MessagingViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import Parse

let defaultBlueColour = UIColor(red: 0, green: CGFloat(122)/255, blue: CGFloat(255)/255, alpha: 255)

class MessagingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextViewDelegate, MessengerDelegate {
    //includes current user
    var toUsers = [String]()
    var messages = [PFObject]()
    var messenger = Messenger()
    var rowsWithTimeStamps = [Int]()
    
    let messageSpacing: CGFloat = 4
    let timeStampHeight: CGFloat = 14
    let labelWidth: CGFloat = 115
    let textViewSpacingInitial: CGFloat = 10
    let textViewSpacingSend: CGFloat = 60
    
    
    @IBOutlet weak var messageTable: UITableView!
    
    @IBOutlet weak var textViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textViewLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dockView: UIView!
    
    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func sendButtonTapped() {
        //self.messageTextView.endEditing(true)
        //self.messageTextView.enabled = false
        self.sendButton.enabled = false
        self.sendButton.setTitleColor(UIColor.grayColor(), forState: .Normal)
        messenger.sendMessage(messageTextView.text, decorationFlag: "n")
    }
    
    func showSend() {
        UIView.animateWithDuration(0.2, animations: {
            self.textViewLeftConstraint.constant = self.textViewSpacingSend
            self.view.layoutIfNeeded()
        })
    }
    
    func hideSend() {
        UIView.animateWithDuration(0.2, animations: {
            self.textViewLeftConstraint.constant = self.textViewSpacingInitial
            self.view.layoutIfNeeded()
            }, completion: {
                (finished) in
                 self.sendButton.setTitleColor(defaultBlueColour, forState: .Normal)
        })
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
        if textView.text == "" {
            println("here")
            hideSend()
        }
        else {
            showSend()
        }
        resizeTextView()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = kbRect.size.height - _currentKeyboardHeight
        _currentKeyboardHeight = kbRect.size.height
        moveKeyboardUpBy(delta, animationTime: animationTime)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = -kbRect.height
        _currentKeyboardHeight = 0
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
    
    func trimSpaces(text: String?) -> String? {
        if text == nil {
            return text
        }
        var nsText: NSString = text!
        var trimmedText = nsText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        println("Trimmed text: \(trimmedText)")
        return trimmedText
    }
    
    @IBOutlet weak var dockViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidDisappear(animated: Bool) {
        println("removing observers")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageNotificationReceivedKey, object: nil)
    }
    
    override func viewDidLoad() {
        println("LOADING")
        super.viewDidLoad()
        setMessageViewBorders()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("messageReceived:"), name: messageNotificationReceivedKey, object: nil)
        println("adding observers")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        println("toUsers: \(toUsers)")
        self.messageTable.delegate = self
        self.messageTable.dataSource = self
        self.messageTextView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        self.messageTable.addGestureRecognizer(tapGesture)
        self.messenger.delegate = self
        self.messenger.getMessageHistoryFrom(toUsers)
        
    }
    
    func setMessageViewBorders() {
        dockView.bringSubviewToFront(messageTextView)
        dockView.layer.borderColor = UIColor.grayColor().CGColor
        dockView.layer.borderWidth = 1.0
        messageTextView.layer.borderColor = UIColor.grayColor().CGColor
        messageTextView.layer.borderWidth = 1.0
        messageTextView.layer.cornerRadius = 5
        messageTextView.layer.masksToBounds = true
        let prevHeight = messageTextView.frame.height
        let sizeThatFitsContent = messageTextView.sizeThatFits(messageTextView.frame.size)
        textViewConstraint.constant = sizeThatFitsContent.height
        dockViewHeightConstraint.constant += (sizeThatFitsContent.height - prevHeight)
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
    
    func messageTapped(sender: AnyObject) {
        println("messageTapped")
        let bubble = sender as! UIButton
        let row = bubble.tag
        
        if let index = find(rowsWithTimeStamps, row) {
            println("reducing size")
            rowsWithTimeStamps.removeAtIndex(index)
        }
        else {
            println("increasing size")
            rowsWithTimeStamps.append(row)
        }
        messageTable.reloadData()
        if row == messages.count - 2 {
            println("Scrolling")
            self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)

        }
        
    }

}

//Table View Methods
extension MessagingViewController {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //println("rowsWithTimes: \(rowsWithTimeStamps)")
        if indexPath.row == 0 || indexPath.row == messages.count - 1 {
            return messageSpacing
        }
        let message = messages[indexPath.row]
        if let dF = message.objectForKey("decorationFlag") as? String {
            if dF == "h" || dF == "t" {
                return 60
            }
        }
        var text = message.objectForKey(parse_message_text) as! String
        var textHeight = getHeightOfLabel(text) + messageSpacing * 2
        if contains(rowsWithTimeStamps, indexPath.row) {
            println("increasing height at row: \(indexPath.row)")
            textHeight += 14
        }
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
        if indexPath.row == 0 || indexPath.row == messages.count - 1 {
            let cell = messageTable.dequeueReusableCellWithIdentifier("Padding") as! UITableViewCell
            cell.textLabel?.text = ""
            return cell
        }
        let message = messages[indexPath.row]
        if let df = message.objectForKey("decorationFlag") as? String {
            if df == "h" {
                let cell = messageTable.dequeueReusableCellWithIdentifier("MeetHere") as! UITableViewCell
                return cell
            }
            if df == "t" {
                let cell = messageTable.dequeueReusableCellWithIdentifier("MeetThere") as! UITableViewCell
                return cell
            }
        }
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        let messageUser = message.objectForKey(parse_message_fromUser) as! PFUser
        if messageUser.objectId == PFUser.currentUser()!.objectId {
            return setUpMessageCell(indexPath, message: message, formatter: formatter)
        }
        else {
            return setUpIncomingMessageCell(indexPath, message: message, formatter: formatter, messageUser: messageUser)
        }
    }
    
    func setUpMessageCell(indexPath: NSIndexPath, message: PFObject, formatter: NSDateFormatter) -> MessageCell {
        let cell = messageTable.dequeueReusableCellWithIdentifier("MessageCell") as! MessageCell
        let parseText = message.objectForKey(parse_message_text) as? String
        cell.messageText.text = trimSpaces(parseText)
        cell.contentView.bringSubviewToFront(cell.messageText)
        cell.messageView.tag = indexPath.row
        cell.messageView.addTarget(self, action: Selector("messageTapped:"), forControlEvents: .TouchUpInside)
        cell.timeStamp.text = formatter.stringFromDate(message.createdAt!)
        if contains(rowsWithTimeStamps, indexPath.row) {
            cell.messageTextBottomConstraint.constant = timeStampHeight + messageSpacing
            cell.messageViewBottomConstraint.constant = timeStampHeight + messageSpacing
            cell.timeStamp.hidden = false
        }
        else {
            cell.messageTextBottomConstraint.constant = messageSpacing
            cell.messageViewBottomConstraint.constant = messageSpacing
            cell.timeStamp.hidden = true
        }
        return cell
    }
    
    func setUpIncomingMessageCell(indexPath: NSIndexPath, message: PFObject, formatter: NSDateFormatter, messageUser: PFObject) -> MessageCell {
        let cell = messageTable.dequeueReusableCellWithIdentifier("IncomingMessageCell") as! MessageCell
        let parseText = message.objectForKey(parse_message_text) as? String
        cell.messageText.text = trimSpaces(parseText)
        cell.contentView.bringSubviewToFront(cell.messageText)
        cell.messageView.tag = indexPath.row
        cell.messageView.addTarget(self, action: Selector("messageTapped:"), forControlEvents: .TouchUpInside)
        cell.timeStamp.text = formatter.stringFromDate(message.createdAt!)
        if let colour = _friendManager.userMap[messageUser.objectId!]?.colour {
            let newcolour = ColourGenerator.getAssociatedColour(colour)
            cell.messageView.backgroundColor = newcolour
            cell.messageText.backgroundColor = newcolour
        }
        if contains(rowsWithTimeStamps, indexPath.row) {
            cell.messageTextBottomConstraint.constant = timeStampHeight + messageSpacing
            cell.messageViewBottomConstraint.constant = timeStampHeight + messageSpacing
            cell.timeStamp.hidden = false
        }
        else {
            cell.messageTextBottomConstraint.constant = messageSpacing
            cell.messageViewBottomConstraint.constant = messageSpacing
            cell.timeStamp.hidden = true
        }
        return cell
    }
}

//Messenger Methods
extension MessagingViewController {
    
    func sentMessage() {
        println("method finished")
        messenger.getMessageHistoryFrom(toUsers)
        if self.messages.count > 0 {
            self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
        }
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTextView.text = ""
            self.hideSend()
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
        rowsWithTimeStamps.removeAll(keepCapacity: true)
        println("message count: \(messages.count)")
        self.messages = messages
        if messages.count > 0 {
            //add padding
            let dummyObject = messages[0]
            self.messages = [dummyObject] + self.messages + [dummyObject]
        }
        println("message count: \(self.messages.count)")
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTable.reloadData()
            if messages.count > 0 {
                self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
                println("to bottom")
            }
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
