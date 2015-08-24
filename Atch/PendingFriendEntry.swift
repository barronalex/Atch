//
//  PendingFriendEntry.swift
//  
//
//  Created by Alex Barron on 8/17/15.
//
//



class PendingFriendEntry: UITableViewCell {
    
    @IBOutlet weak var name: UITextField!
    
    @IBOutlet weak var username: UITextField!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var acceptButton: UIButton!
    
    override func awakeFromNib() {
        username.userInteractionEnabled = false
        name.userInteractionEnabled = false
    }
}
