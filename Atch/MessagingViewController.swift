//
//  MessagingViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import Parse

class MessagingViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MessengerDelegate {
    //includes current user
    var toUsers = [String]()
    var messages = [PFObject]()
    var messenger = Messenger()
    
    
    @IBOutlet weak var messageTable: UITableView!
    
    @IBOutlet weak var messageTextField: UITextField!
    
    @IBOutlet weak var sendButton: UIButton!
    
    @IBAction func sendButtonTapped() {
        self.messageTextField.endEditing(true)
        self.messageTextField.enabled = false
        self.sendButton.enabled = false
        messenger.sendMessage(messageTextField.text)
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: {
            
            self.dockViewHeightConstraint.constant = 290
            self.messageTable.setContentOffset(CGPoint(x: 0, y: 650), animated: true)
            self.view.layoutIfNeeded()
            
            }, completion: nil)
        
    }
    
    func textFieldDidEndEditing(textField: UITextField) {
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(0.5, animations: {
            
            self.dockViewHeightConstraint.constant = 60
            self.view.layoutIfNeeded()
            
            }, completion: nil)
    }
    
    func tableViewTapped() {
        self.messageTextField.endEditing(true)
    }
    
    @IBOutlet weak var dockViewHeightConstraint: NSLayoutConstraint!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        println("toUsers: \(toUsers)")
        self.messenger.delegate = self
        self.messenger.getMessageHistoryFrom(toUsers)
        self.messageTable.delegate = self
        self.messageTable.dataSource = self
        self.messageTextField.delegate = self
        let tapGesture = UITapGestureRecognizer(target: self, action: "tableViewTapped")
        self.messageTable.addGestureRecognizer(tapGesture)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
        // Most of the time my data source is an array of something...  will replace with the actual name of the data source
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = messageTable.dequeueReusableCellWithIdentifier("MessageCell") as! UITableViewCell
        cell.textLabel?.text = messages[indexPath.row].objectForKey("messageText") as? String
        return cell
    }
    
    func sentMessage() {
        messenger.getMessageHistoryFrom(toUsers)
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTextField.text = ""
            self.messageTextField.enabled = true
            self.sendButton.enabled = true
        }
    }
    
    func gotPreviousMessages(messages: [PFObject]) {
        //display messages
        println("got messages")
        println("message count: \(messages.count)")
        self.messages = messages
        dispatch_async(dispatch_get_main_queue()) {
            self.messageTable.reloadData()
            self.messageTable.scrollToRowAtIndexPath(NSIndexPath(forRow: messages.count - 1, inSection: 0), atScrollPosition: UITableViewScrollPosition.Bottom, animated: false)
        }
        
    }

}
