//
//  IncomingMessageCell.swift
//  Atch
//
//  Created by Alex Barron on 8/21/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit

class IncomingMessageCell: MessageCell {
    
    @IBOutlet weak var timeStampLeft: UILabel!
    
    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        timeStampLeft.hidden = true
        // Initialization code
        messageView.layer.cornerRadius = 5
        messageView.layer.masksToBounds = true
    }

}
