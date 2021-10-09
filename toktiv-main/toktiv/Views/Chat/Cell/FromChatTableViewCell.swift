//
//  FromChatTableViewCell.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 25/08/2021.
//

import UIKit

class FromChatTableViewCell: UITableViewCell {

    @IBOutlet weak var mediaImageView:UIImageView!
    @IBOutlet weak var timeLabel:UILabel!
    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var messageTextView:UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
