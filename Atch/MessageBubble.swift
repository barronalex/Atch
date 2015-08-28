//
//  MessageBubble.swift
//  Atch
//
//  Created by Alex Barron on 8/27/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class MessageBubble: UILabel {
    
    override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: 0, left: 5, bottom: 0, right: 5)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
    
}