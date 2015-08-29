//
//  NotificationBanner.swift
//  Atch
//
//  Created by Alex Barron on 8/26/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse

let notification_banner_height: CGFloat = 100
let notification_text_height: CGFloat = 20
let notification_text_margin: CGFloat = 20
let notification_top_margin: CGFloat = 20

var _notificationBanner = NotificationBanner()

class NotificationBanner: NSObject {
    
    var toUsers = [String]()
    var type = ""
    var notifView = UIView()
    var view: UIView?
    
    func displayNotification(text: String, type: String, toUsers: [String]) {
        self.toUsers = toUsers
        self.type = type
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        self.view = curVC.view
        for user in toUsers {
            if user != PFUser.currentUser()!.objectId! {
                println("user: \(user)")
                setUpView(self.view!, user: user)
            }
        }
        
        let notifText = setUpLabel(self.view!, text: text)
        notifView.addSubview(notifText)
        self.view!.bringSubviewToFront(notifView)
        UIView.animateWithDuration(0.5, animations: {
            self.notifView.frame.origin.y = 0
            notifText.frame.origin.y = (notification_banner_height/2 - notification_text_height/2) + notification_top_margin/2
        })
        //put banner back up
        NSTimer.scheduledTimerWithTimeInterval(3, target: self, selector: Selector("putBannerDown:"), userInfo: ["notifView":notifView], repeats: false)
    }
    
    private func setUpLabel(view: UIView, text: String) -> UILabel{
        let notifText = UILabel()
        notifText.text = text
        notifText.textColor = UIColor.whiteColor()
        let maxsize = CGSize(width: view.frame.width - notification_text_margin * 2, height: notification_text_height)
        let actualsize = notifText.sizeThatFits(maxsize)
        notifText.frame = CGRectMake(notification_text_margin + ((view.frame.width - notification_text_margin * 2) - actualsize.width)/2, (notification_banner_height/2 - notification_text_height/2) + notification_top_margin, actualsize.width, actualsize.height)
        return notifText

    }
    
    private func setUpView(view: UIView, user: String?) {
        notifView = UIView(frame: CGRectMake(0, -notification_banner_height, view.frame.width, notification_banner_height))
        if user != nil {
            let colour = _friendManager.userMap[user!]!.colour!
            println("assign colour")
            notifView.backgroundColor = colour
            
        }
        else {
            notifView.backgroundColor = UIColor.whiteColor()
        }
        view.addSubview(notifView)
        
        notifView.alpha = 0.9
        let tapGesture = UITapGestureRecognizer(target: self, action: Selector("notificationTapped"))
        notifView.addGestureRecognizer(tapGesture)
        let panGesture = UIPanGestureRecognizer(target: self, action: Selector("notificationSwiped:"))
        notifView.addGestureRecognizer(panGesture)
    }
    
    func notificationSwiped(recognizer: UIPanGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Ended {
            if notifView.frame.origin.y < 0 {
                UIView.animateWithDuration(0.5, animations: {
                    self.notifView.frame.origin.y = -notification_banner_height
                    }, completion: {
                        (finished) in
                        self.notifView.removeFromSuperview()
                })
            }
        }
        let yTranslation = recognizer.translationInView(self.view!).y
        if notifView.frame.origin.y + yTranslation > 0 {
            notifView.frame.origin.y = 0
        }
        else {
            notifView.frame.origin.y += yTranslation
        }
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