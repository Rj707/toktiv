//
//  SMSHistoryCell.swift
//  toktiv
//
//  Created by Developer on 14/11/2020.
//

import UIKit

class SMSHistoryCell: UITableViewCell {
    var smsRecord:HistoryResponseElement?

    @IBOutlet weak var fromLabel:UILabel!
    @IBOutlet weak var contentLabel:UILabel!
    @IBOutlet weak var dateLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    var topName:String {
        if smsRecord?.direction?.lowercased() == "inbound" {
            if smsRecord?.fromName?.count ?? 0 > 0 {
                return smsRecord?.fromName ?? ""
            }
            
            if smsRecord?.from?.count ?? 0 > 0 {
                return smsRecord?.from ?? ""
            }
        }
        else {
            if smsRecord?.toName?.count ?? 0 > 0 {
                return smsRecord?.toName ?? ""
            }
            
            if smsRecord?.to?.count ?? 0 > 0 {
                return smsRecord?.to ?? ""
            }
        }
        
        return "anonymous"
    }

    override func layoutSubviews() {
        if let validSMS = self.smsRecord {
            fromLabel.text = self.topName
            contentLabel.text = validSMS.content ?? " "
            dateLabel.text = "\(validSMS.date ?? " ") \(validSMS.time ?? " ")"
        }
    }
}
