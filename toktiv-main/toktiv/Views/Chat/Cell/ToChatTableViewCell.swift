//
//  AttachmentTableViewCell.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 25/08/2021.
//

import UIKit

class ToChatTableViewCell: UITableViewCell {

    @IBOutlet weak var mediaImageView:UIImageView!
    @IBOutlet weak var timeLabel:UILabel!
    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var messageTextView:UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    
}
