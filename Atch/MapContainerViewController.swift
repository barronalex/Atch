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
    var toUsers = [String]()
    
    func goToMessages(toUsers: [String]) {
        self.toUsers = toUsers
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
        childVCs.removeAll(keepCapacity: true)
    }
    
    override func viewDidLoad() {
        self.view.alpha = 0.95
    }
    
}