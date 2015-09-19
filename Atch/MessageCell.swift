//
//  MessageCell.swift
//  Atch
//
//  Created by Alex Barron on 8/21/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit

class MessageCell: UITableViewCell {

    @IBOutlet weak var messageText: UILabel!
    
    @IBOutlet weak var messageView: UIButton!
    
    @IBOutlet weak var timeStamp: UILabel!
    
    @IBOutlet weak var messageViewBottomConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var messageTextBottomConstraint: NSLayoutConstraint!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        timeStamp.hidden = true
        //messageView.layer.backgroundColor = UIColor.blackColor().CGColor
        messageView.layer.cornerRadius = 12
       // messageView.layer.borderColor = UIColor.blackColor().CGColor
     //   messageView.layer.borderWidth = 1
        messageView.layer.masksToBounds = false
        //messageView.layer.shouldRasterize = true
    }

}
