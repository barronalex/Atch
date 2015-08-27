//
//  NotificationBanner.swift
//  Atch
//
//  Created by Alex Barron on 8/26/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

let notification_banner_height: CGFloat = 80
let notification_text_height: CGFloat = 20
let notification_text_margin: CGFloat = 20
let notification_top_margin: CGFloat = 20

var _notificationBanner = NotificationBanner()

class NotificationBanner: NSObject {
    
    var toUsers = [String]()
    var type = ""
    var notifView = UIView()
    
    func displayNotification(text: String, type: String, toUsers: [String]) {
        self.toUsers = toUsers
        self.type = type
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        let view = curVC.view
        //make banner in main view and animate it down
        //make container view controller in current view of certain width and height
        //set its child to notification banner 
        notifView = UIView(frame: CGRectMake(0, -notification_banner_height, view.frame.width, notification_banner_height))
        
        view.addSubview(notifView)
        notifView.backgroundColor = UIColor.grayColor()
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("notificationTapped"))
        notifView.addGestureRecognizer(tapGesture)
        let notifText = UILabel()
        notifText.text = text
        let maxsize = CGSize(width: view.frame.width - notification_text_margin * 2, height: notification_text_height)
        let actualsize = notifText.sizeThatFits(maxsize)
        notifText.frame = CGRectMake(notification_text_margin + ((view.frame.width - notification_text_margin * 2) - actualsize.width)/2, (notification_banner_height/2 - notification_text_height/2) + notification_top_margin, actualsize.width, actualsize.height)
        notifView.addSubview(notifText)
        view.bringSubviewToFront(notifView)
        UIView.animateWithDuration(0.5, animations: {
            self.notifView.frame.origin.y = 0
            notifText.frame.origin.y = (notification_banner_height/2 - notification_text_height/2) + notification_top_margin/2
        })
        //put banner back up
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector("putBannerDown:"), userInfo: ["notifView":notifView], repeats: false)
    }
    
    func putBannerDown(notification: NSNotification) {
        if let notifView = notification.userInfo!["notifView"] as? UIView {
            UIView.animateWithDuration(0.5, animations: {
                notifView.frame.origin.y = -notification_banner_height
                }, completion: {
                    (finished) in
                    notifView.removeFromSuperview()
            })
        }
    }
    
    func notificationTapped() {
        println("notification tapped")
        if let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController) as? IntroViewController {
            notifView.backgroundColor = UIColor.redColor()
        }
        else {
            if type == "friendRequest" {
                Navigator.goToAddFriends()
            }
            else if type == "friendAccept" {
                Navigator.goToFriends()
            }
            else if type == "message" {
                Navigator.goToMessages(self.toUsers)
            }
        }
        
    }
}