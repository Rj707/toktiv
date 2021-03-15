//
//  FromCell.swift
//  toktiv
//
//  Created by Developer on 23/11/2020.
//

import UIKit

class FromCell: UITableViewCell {
    var smsRecord:HistoryResponseElement?

    @IBOutlet weak var messageLabel:UILabel!
    @IBOutlet weak var timeLabel:UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        superview?.layoutSubviews()
        
        self.messageLabel.text = smsRecord?.content ?? ""
        timeLabel.text = "\(smsRecord?.date ?? " ") \(smsRecord?.time ?? " ")"

    }
}
