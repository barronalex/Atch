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
        //timeStamp.hidden = true
        // Initialization code
        messageView.layer.cornerRadius = 5
        messageView.layer.masksToBounds = true
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        //timeStamp.hidden = true
        // Configure the view for the selected state
    }

}
