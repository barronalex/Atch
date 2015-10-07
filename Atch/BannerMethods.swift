//
//  BannerMethods.swift
//  Atch
//
//  Created by Alex Barron on 9/2/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import Parse

//#MARK: Banner Methods
extension AtchMapViewController {
    
    
    @IBAction func handlePan(recognizer:UIPanGestureRecognizer) {
        if tappedUserIds == [PFUser.currentUser()!.objectId!] { return }
        if recognizer.state == UIGestureRecognizerState.Ended {
            bannerTapped()
            return
        }
        print("here")
            if recognizer.state == UIGestureRecognizerState.Began && self.bannerAtTop {
                self.bannerHeightConstraint.constant = self.bannerHeightAtBottom
                self.view.endEditing(true)
                
            }
            let yTranslation = recognizer.translationInView(self.view).y
            if let _ = recognizer.view {
                if (self.bannerConstraint.constant - yTranslation) > (self.view.frame.height - self.bannerView.frame.height) {
                    self.bannerConstraint.constant = self.view.frame.height - self.bannerView.frame.height
                    self.topContainerConstraint.constant = self.bannerView.frame.height - self.topMargin
                }
                else if (self.bannerConstraint.constant - yTranslation) < 0 {
                    self.bannerConstraint.constant = 0
                    self.topContainerConstraint.constant = self.view.frame.height - self.topMargin
                }
                else {
                    self.bannerConstraint.constant -= yTranslation
                    self.topContainerConstraint.constant += yTranslation
                }
                
            }
        
        
        recognizer.setTranslation(CGPointZero, inView: self.view)
    }
    
    func bannerTapped() {
        print("banner tapped")
        if tappedUserIds == [PFUser.currentUser()!.objectId!] { return }
        if !self.bannerAtTop {
            UIView.animateWithDuration(NSTimeInterval(0.3), animations: {
                _mapView?.padding = self.bannerMapInsets
                self.topContainerConstraint.constant = self.bannerView.frame.height - self.topMargin - (self.bannerHeightAtBottom - self.bannerHeightAtTop)
                
                self.bannerConstraint.constant = self.view.frame.height - self.bannerView.frame.height + (self.bannerHeightAtBottom - self.bannerHeightAtTop)
                print("bannerConstraint: \(self.bannerConstraint.constant)")
                print("banner height: \(self.bannerHeightAtTop)")
                self.bannerHeightConstraint.constant = self.bannerHeightAtTop
                self.containerHeightConstraint.constant = self.view.frame.height - self.bannerHeightAtTop
                self.view.layoutIfNeeded()
            })
            self.bannerAtTop = true
        }
        else {
            self.lowerBanner()
        }

        print("banner height real: \(bannerView.frame.height)")
    }
    
    func lowerBanner() {
//        dispatch_async(dispatch_get_main_queue(), {
            self.view.layoutIfNeeded()
            UIView.animateWithDuration(NSTimeInterval(self.bannerAppearAnimationTime), animations: {
                self.bannerConstraint.constant = 0
                self.topContainerConstraint.constant = self.view.frame.height - 20
                _mapView?.padding = self.bannerMapInsets
                self.bannerHeightConstraint.constant = self.bannerHeightAtBottom
                self.containerHeightConstraint.constant -= (self.bannerHeightAtBottom - self.bannerHeightAtTop)
                self.view.layoutIfNeeded()
            })
            self.bannerAtTop = false
            self.tappedUserIds = []
            self.view.endEditing(true)
//        })
        
    }
    
    func setBannerText() {
        var bannerText = ""
        bannerLabel.adjustsFontSizeToFitWidth = true
        for userId in tappedUserIds {
            if let firstname = _friendManager.userMap[userId]?.parseObject?.objectForKey("firstname") as? String {
                bannerText += (firstname + ", ")
                
            }
        }
        if bannerText.characters.count > 1 {
            bannerText = bannerText.substringToIndex(bannerText.endIndex.predecessor().predecessor())
        }
        bannerLabel.text = bannerText
    }
    
    func setBannerColour() {
        if tappedUserIds.count == 1 {
            let colour = _friendManager.userMap[tappedUserIds[0]]?.colour
            bannerView.backgroundColor = colour
            if let image = _friendManager.userMap[tappedUserIds[0]]?.image {
                self.bannerImage.image = ImageProcessor.createCircle(image)
            }
            
        }
        else {
            bannerView.backgroundColor = UIColor.blackColor()
            if let group = _friendManager.groupMap[Group.generateHashStringFromArray(tappedUserIds)] {
                self.bannerImage.image = group.image
            }
        }
    }
    
    func putBannerUp() {
        
        setBannerColour()
        setBannerText()
        self.view.bringSubviewToFront(bannerView)
        self.view.bringSubviewToFront(containerView)
        self.view.layoutIfNeeded()
        UIView.animateWithDuration(NSTimeInterval(self.bannerAppearAnimationTime), animations: {
            self.bannerConstraint.constant = 0
            _mapView?.padding = self.bannerMapInsets
            self.view.layoutIfNeeded()
        })
        
        self.bannerUp = true
        if tappedUserIds != [PFUser.currentUser()!.objectId!] {
            let toUsers = tappedUserIds
            containerVC?.goToMessages(toUsers)
        }
        
        
        print("friend map count: \(_friendManager.friends.count)")
        print("tapped id: \(tappedUserIds)")
        
        print("BANNER TEXT: \(bannerLabel.text)")
        
        //dispatch_async(dispatch_get_main_queue(), {
        
        //})
        
    }
    
    func switchBanners() {
        self.view.endEditing(true)
        self.containerVC?.removeChildren()
        let toUsers = tappedUserIds
        containerVC?.goToMessages(toUsers)
        //put up banner
        print("friend map count: \(_friendManager.friends.count)")
        print("tapped id: \(tappedUserIds)")
        setBannerColour()
        setBannerText()
        
    }
    
    func putBannerDown() {
        self.view.endEditing(true)
//        dispatch_async(dispatch_get_main_queue(), {
            UIView.animateWithDuration(NSTimeInterval(0.3), animations: {
                self.topContainerConstraint.constant = self.view.frame.height - 20
                self.bannerConstraint.constant = -self.bannerView.frame.height
                _mapView?.padding = self.zeroMapInsets
                self.bannerHeightConstraint.constant = self.bannerHeightAtBottom
                self.containerHeightConstraint.constant -= (self.bannerHeightAtBottom - self.bannerHeightAtTop)
                self.view.layoutIfNeeded()
                }, completion: {
                    (finished) in
                    self.containerVC?.removeChildren()
            })
            self.bannerUp = false
            self.bannerAtTop = false
            self.tappedUserIds = []
//        })
        
    }
    
    func bringUpMessagesScreen() {
        putBannerUp()
        bannerAtTop = false
        bannerTapped()
    }
    
}
