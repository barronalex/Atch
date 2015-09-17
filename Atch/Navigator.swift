//
//  Navigator.swift
//  Atch
//
//  Created by Alex Barron on 8/27/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class Navigator {
    
    static func getVisibleViewController(rootVC: UIViewController?) -> UIViewController {
        if rootVC!.presentedViewController == nil {
            return rootVC!
        }
        return getVisibleViewController(rootVC!.presentedViewController)
    }
    
    static func goToIntro() {
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        if curVC is IntroViewController {
            return
        }
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let loginVC = storyboard.instantiateViewControllerWithIdentifier("IntroViewController") as! IntroViewController
        curVC.showViewController(loginVC, sender: nil)
    }
    
    static func goToFriends() {
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        if curVC is LoginViewController {
            return
        }
        if !(curVC is FriendsViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("FriendsViewController") as! FriendsViewController
            curVC.showViewController(loginVC, sender: nil)
        }
        _friendManager.getFriends()
    }
    
    static func goToAddFriends() {
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        if curVC is LoginViewController {
            return
        }
        if !(curVC is AddFriendsViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("AddFriendsViewController") as! AddFriendsViewController
            curVC.showViewController(loginVC, sender: nil)
        }
        _friendManager.getFriends()
    }
    
    static func goToMessages(toUsers: [String]) {
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        if curVC is LoginViewController {
            return
        }
        println("past clauses")
        if let atchVC = curVC as? AtchMapViewController {
            println("ATCH MAP CONTROLLER PRESENTED")
            atchVC.lowerBanner()
            atchVC.tappedUserIds = toUsers
            atchVC.containerVC?.goToMessages(toUsers)
            atchVC.bannerAtTop = false
            atchVC.switchBanners()
            atchVC.bannerTapped()
        }
        else if let introVC = curVC as? IntroViewController { }
        else if let friendsVC = curVC as? FriendsViewController {
            println("FRIEND VIEWCONTROLLER PRESENTED")
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let atchVC = storyboard.instantiateViewControllerWithIdentifier("AtchMapViewController") as! AtchMapViewController
            curVC.showViewController(atchVC, sender: nil)
            atchVC.tappedUserIds = toUsers
            atchVC.containerVC?.goToMessages(toUsers)
            atchVC.bringUpMessagesScreen()
            if let friendLocation = _friendManager.userMap[toUsers[1]]?.marker?.position {
                println("animating")
                _mapView?.animateToLocation(friendLocation)
            }
        }
    }
    
    static func goToLogin() {
        let curVC = Navigator.getVisibleViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        if !(curVC is LoginViewController)  {
            let storyboard = UIStoryboard(name: "Main", bundle: nil)
            let loginVC = storyboard.instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
            curVC.showViewController(loginVC, sender: nil)
        }
    }
}