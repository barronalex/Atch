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
    var heights = [CGFloat]()
    var responsesMap = [Int:[PFObject]]()
    var messageResponses = [Int:Bool]()
    var rowsWithTimeStamps = [Int]()
    var currentMessageCount = 0
    var dummyMessages = [PFObject]()
    
    let messageSpacing: CGFloat = 4
    let bubbleBorder: CGFloat = 4
    let timeStampHeight: CGFloat = 14
    let labelWidth: CGFloat = 120
    let textViewSpacingInitial: CGFloat = 10
    let textViewSpacingSend: CGFloat = 60
    let responseHeight = 52
    
    
    @IBOutlet weak var messageTable: UITableView!
    
    @IBOutlet weak var textViewConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var textViewLeftConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var dockView: UIView!
    
    @IBOutlet weak var messageTextView: UITextView!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func sendButtonTapped() {
        print("sendButtonTapped")
        let messageText = trimSpaces(messageTextView.text)
        if messageText == "" { return }
        addTemporaryMessage(messageText)
        self.messageTextView.text = ""
        self.hideSend()
        self.resizeTextView()
        messenger.sendMessage(messageText, decorationFlag: "n", goToBottom: true)
        
        
    }
    
    func trimSpaces(text: String) -> String {
        let nsText: NSString = text
        let trimmedText = nsText.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
        print("Trimmed text: \(trimmedText)")
        return trimmedText
    }
    
    func addTemporaryMessage(text: String) {
        let tempMessage = PFObject(className: "Message")
        tempMessage.setObject(text, forKey: "messageText")
        tempMessage.setObject(PFUser.currentUser()!, forKey: "fromUser")
        tempMessage.setObject("y", forKey: "pending")
        if messages.count > 0 {
            messages.removeLast()

        }
        messages.append(tempMessage)
        messages.append(tempMessage)
        messageTable.reloadData()
        self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
        print("to bottom")
        print("temporary message added")
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
            let prevHeight = self.messageTextView.frame.height
            let sizeThatFitsContent = self.messageTextView.sizeThatFits(self.messageTextView.frame.size)
            self.textViewConstraint.constant = sizeThatFitsContent.height
            self.dockViewHeightConstraint.constant += (sizeThatFitsContent.height - prevHeight)
            print("change: \(sizeThatFitsContent.height - prevHeight)")
            let offset = sizeThatFitsContent.height - prevHeight
            print("offset: \(offset)")
            self.messageTable.contentOffset.y += offset
    }
    
    func textViewDidChange(textView: UITextView) {
        if textView.text == "" {
            print("here")
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
        print("keyboard showing: \(kbRect.height)")
        moveKeyboardUpBy(delta, animationTime: animationTime)
    }
    
    func keyboardWillHide(notification: NSNotification) {
        let info = notification.userInfo
        let value = info![UIKeyboardFrameEndUserInfoKey] as! NSValue
        let kbRect = value.CGRectValue()
        let animationTime = info![UIKeyboardAnimationDurationUserInfoKey] as! NSNumber
        let delta = -kbRect.size.height
        _currentKeyboardHeight = 0
        print("keyboard hiding: \(kbRect.height)")
        moveKeyboardUpBy(delta, animationTime: animationTime)
    }
    
    func moveKeyboardUpBy(delta: CGFloat, animationTime: NSNumber) {
        self.view.layoutIfNeeded()
        print("DELTA: \(delta)")
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
    
    // #MARK: View Controller Methods
    
    override func viewDidDisappear(animated: Bool) {
        print("removing observers")
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: UIKeyboardWillHideNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: messageNotificationReceivedKey, object: nil)
    }
    
    override func viewDidLoad() {
        print("LOADING")
        super.viewDidLoad()
        setMessageViewBorders()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("messageReceived:"), name: messageNotificationReceivedKey, object: nil)
        print("adding observers")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
            NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
        print("toUsers: \(toUsers)")
        self.messageTable.delegate = self
        self.messageTable.dataSource = self
        self.messageTextView.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        tapGesture.cancelsTouchesInView = false
        self.messageTable.addGestureRecognizer(tapGesture)
        self.messenger.delegate = self
        print("getting cache")
        self.messages = self.messenger.getCachedMessages(toUsers)
        gotPreviousMessages(self.messages, toBottom: true)
        print("after cache")
        self.messenger.getMessageHistoryFrom(toUsers, toBottom: true)
        
        
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
        self.textViewConstraint.constant = sizeThatFitsContent.height
        self.dockViewHeightConstraint.constant += (sizeThatFitsContent.height - prevHeight)
        
    }
    
    func getHeightOfLabel(text: String) -> CGFloat {
        let sizeGettingLabel = UILabel()
        sizeGettingLabel.font = UIFont.systemFontOfSize(17)
        sizeGettingLabel.text = text
        sizeGettingLabel.numberOfLines = 0
        sizeGettingLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        let maxSize = CGSizeMake(self.view.frame.width - labelWidth, 9999)
        let expectedSize = sizeGettingLabel.sizeThatFits(maxSize)
        return expectedSize.height
    }
    
    func messageTapped(sender: AnyObject) {
        print("messageTapped")
        let bubble = sender as! UIButton
        let row = bubble.tag
        
        if let index = rowsWithTimeStamps.indexOf(row) {
            print("reducing size")
            rowsWithTimeStamps.removeAtIndex(index)
        }
        else {
            print("increasing size")
            rowsWithTimeStamps.append(row)
        }
        messageTable.reloadData()
        if row == messages.count - 2 {
            print("Scrolling")
            self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)

        }
        
    }

}

//Table View Methods
extension MessagingViewController {
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        //print("rowsWithTimes: \(rowsWithTimeStamps)")
        let row = indexPath.row
        if row == 0 || row == messages.count - 1 {
            return messageSpacing
        }
        let message = messages[row]
        if let dF = message.objectForKey("decorationFlag") as? String {
            if dF == "h" || dF == "t" {
                let result = MeetHereCell.getResponsesFromMessages(self.messages, row: row)
                messageResponses[row] = result.1
                responsesMap[row] = result.0
                var height = responseHeight + 8
                height += (result.0.count * (responseHeight - 8))
                if !result.1 {
                    height += 2 * (responseHeight - 8)
                }
                print("HEIGHT: \(height)")
                return CGFloat(height)
                
            }
            if dF == "r" {
                return 0
            }
        }
        let text = message.objectForKey(parse_message_text) as! String
        var textHeight = getHeightOfLabel(text) + messageSpacing * 2 + bubbleBorder * 2
        
        //print("TEXT HEIGHT: \(textHeight)")
        if rowsWithTimeStamps.contains(row) {
            //print("increasing height at row: \(indexPath.row)")
            textHeight += timeStampHeight
        }
        
        return textHeight
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        if indexPath.row == 0 || indexPath.row == messages.count - 1 {
            let cell = messageTable.dequeueReusableCellWithIdentifier("Padding")!
            cell.textLabel?.text = ""
            return cell
        }
        let formatter = NSDateFormatter()
        formatter.dateFormat = "h:mm a"
        let message = messages[indexPath.row]
        let messageUser = message.objectForKey(parse_message_fromUser) as! PFUser
        if let df = message.objectForKey("decorationFlag") as? String {
            if df != "n" {
                return setUpDecoratedMessage(indexPath, message: message, messageUser: messageUser, formatter: formatter, decorationFlag: df)
                //return messageTable.dequeueReusableCellWithIdentifier("Padding")!
            }
        }
        
        if messageUser.objectId == PFUser.currentUser()!.objectId {
            return setUpMessageCell(indexPath, message: message, formatter: formatter)
        }
        else {
            return setUpIncomingMessageCell(indexPath, message: message, formatter: formatter, messageUser: messageUser)
        }
    }
    
    func tableView(tableView: UITableView, willDisplayCell cell: UITableViewCell, forRowAtIndexPath indexPath: NSIndexPath) {
        UIView.performWithoutAnimation( {
            cell.layoutIfNeeded()
        })
    }
    
}

//Cell Methods
extension MessagingViewController {
    func setUpMessageCell(indexPath: NSIndexPath, message: PFObject, formatter: NSDateFormatter) -> MessageCell {
        let cell = messageTable.dequeueReusableCellWithIdentifier("MessageCell") as! MessageCell
        let parseText = message.objectForKey(parse_message_text) as? String
        cell.messageText.text = parseText
        cell.contentView.bringSubviewToFront(cell.messageText)
        cell.messageView.tag = indexPath.row
        cell.messageView.addTarget(self, action: Selector("messageTapped:"), forControlEvents: .TouchUpInside)
        if let time = message.createdAt {
            cell.timeStamp.text = formatter.stringFromDate(time)
        }
        if (message.objectForKey("pending") as? String != nil) {
            print("changing alpha")
            cell.messageView.alpha = 0.5
            cell.messageText.alpha = 0.5
        }
        else {
            cell.messageView.alpha = 1
            cell.messageText.alpha = 1
        }
        if self.rowsWithTimeStamps.contains(indexPath.row) {
            cell.messageViewBottomConstraint.constant = self.timeStampHeight + self.messageSpacing
            cell.timeStamp.hidden = false
        }
        else {
            cell.messageViewBottomConstraint.constant = self.messageSpacing
            cell.timeStamp.hidden = true
        }
        
        return cell
    }
    
    func setUpDecoratedMessage(indexPath: NSIndexPath, message: PFObject, messageUser: PFUser, formatter: NSDateFormatter, decorationFlag: String) -> UITableViewCell {
        if decorationFlag == "r" {
            return messageTable.dequeueReusableCellWithIdentifier("Blank")!
        }
        if messageUser.objectId == PFUser.currentUser()!.objectId {
            let cell = messageTable.dequeueReusableCellWithIdentifier("MeetHere") as! MeetHereCell
            //cell.meetHereLabel.text = "FROM"
            if let responses = responsesMap[indexPath.row] {
                cell.responses =  responses
                cell.responded = messageResponses[indexPath.row]!
            }
            else{
                let result =  MeetHereCell.getResponsesFromMessages(self.messages, row: indexPath.row)
                cell.responses = result.0
                cell.responded = result.1
            }
            cell.df = decorationFlag
            cell.messageUser = messageUser.objectId!
            cell.messenger = messenger
            cell.message = message.objectId!
            cell.responseTable?.reloadData()
            print("FROM")
            return cell
        }
        else {
            let cell = messageTable.dequeueReusableCellWithIdentifier("MeetHere") as! MeetHereCell
            //cell.meetHereLabel.text = "TO"
            let result = MeetHereCell.getResponsesFromMessages(self.messages, row: indexPath.row)
            cell.responses = result.0
            cell.responded = result.1
            cell.df = decorationFlag
            cell.messageUser = messageUser.objectId!
            cell.messenger = messenger
            cell.message = message.objectId!
            cell.responseTable?.reloadData()
            print("TO")
            return cell
        }
        //return UITableViewCell()
    }
    
    func setUpIncomingMessageCell(indexPath: NSIndexPath, message: PFObject, formatter: NSDateFormatter, messageUser: PFObject) -> MessageCell {
        let cell = messageTable.dequeueReusableCellWithIdentifier("IncomingMessageCell") as! MessageCell
        let parseText = message.objectForKey(parse_message_text) as? String
        cell.messageText.text = parseText
        cell.contentView.bringSubviewToFront(cell.messageText)
        cell.messageView.tag = indexPath.row
        cell.messageView.addTarget(self, action: Selector("messageTapped:"), forControlEvents: .TouchUpInside)
        if let time = message.createdAt {
            cell.timeStamp.text = formatter.stringFromDate(time)
        }
        if let colour = _friendManager.userMap[messageUser.objectId!]?.colour {
            let newcolour = ColourGenerator.getAssociatedColour(colour)
            cell.messageView.backgroundColor = newcolour
            cell.messageText.backgroundColor = newcolour
        }
        if rowsWithTimeStamps.contains(indexPath.row) {
            cell.messageViewBottomConstraint.constant = timeStampHeight + messageSpacing
            cell.timeStamp.hidden = false
        }
        else {
            cell.messageViewBottomConstraint.constant = messageSpacing
            cell.timeStamp.hidden = true
        }
        return cell
    }

}

//Messenger Methods
extension MessagingViewController {
    
    func sentMessage(goToBottom: Bool) {
        print("method finished")
        messenger.getMessageHistoryFrom(toUsers, toBottom: goToBottom)
//        if self.messages.count > 0 && goToBottom {
//            self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: true)
//        }
    }
    
    func refreshMessages() {
        messenger.getMessageHistoryFrom(toUsers, toBottom: true)
        print("refreshing")
    }
    
    func calculateHeights() {
        for var row = 0; row < messages.count; row++ {
           
        }
    }
    
    func gotPreviousMessages(messages: [PFObject], toBottom: Bool) {
        //display messages
        print("got messages")
        rowsWithTimeStamps.removeAll(keepCapacity: true)
        print("message count: \(messages.count)")
        self.messages = messages
        if messages.count > 0 {
            //add padding
            let dummyObject = messages[0]
            //before setting messages change heights
            self.messages = [dummyObject] + self.messages + [dummyObject]
            //calculateHeights()
        }
        print("message count: \(self.messages.count)")
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTable.reloadData()
            if messages.count > 0 && toBottom /*&& messages.count > self.currentMessageCount*/ {
                self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Top, animated: false)
                print("to bottom")
            }
            self.currentMessageCount = self.messages.count
        }
    }
    
    func messageReceived(notification: NSNotification) {
        print("message received")
        let userInfo = notification.userInfo
        if userInfo != nil {
            if let toUsers = userInfo!["toUsers"] as? [String] {
                self.toUsers = toUsers
            }
        }
        
        self.refreshMessages()
    }

}
