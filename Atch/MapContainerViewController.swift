//
//  MapContainerViewController.swift
//  Atch
//
//  Created by Alex Barron on 8/25/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class MapContainerViewController: UIViewController {
    
    var childVCs = [UIViewController]()
    
    func goToMessages(toUsers: [String]) {
        //add a messagingviewcontroller as a child view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let messageVC = storyboard.instantiateViewControllerWithIdentifier("MessagingViewController") as! MessagingViewController
        messageVC.toUsers = toUsers
        self.addChildViewController(messageVC)
        println("width in container: \(self.view.frame.width)")
        messageVC.view.frame = self.view.frame
        self.view.addSubview(messageVC.view)
        messageVC.didMoveToParentViewController(self)
        childVCs.append(messageVC)
//        let hconstraint = NSLayoutConstraint(item: self.view, attribute: NSLayoutAttribute.Left, relatedBy: NSLayoutRelation.Equal, toItem: messageVC.view, attribute: NSLayoutAttribute.Left, multiplier: 1, constant: 0)
//        self.view.addConstraint(hconstraint)
        self.view.layoutIfNeeded()
    }
    
    func removeChildren() {
        for childVC in childVCs {
            childVC.willMoveToParentViewController(nil)
            childVC.view.removeFromSuperview()
            childVC.removeFromParentViewController()
            println("disappearing VC")
            childVC.viewDidDisappear(false)
        }
    }
    
    override func viewDidLoad() {
        
    }
    
}