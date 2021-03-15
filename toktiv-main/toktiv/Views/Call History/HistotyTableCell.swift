//
//  HistotyTableCell.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import UIKit

class HistotyTableCell: UITableViewCell {
    
    var callRecord:HistoryResponseElement?
    
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var numberLabel:UILabel!
    @IBOutlet weak var durationLabel:UILabel!
    @IBOutlet weak var dateLabel:UILabel!
    
    @IBOutlet weak var icon:UIImageView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        if let validCall = self.callRecord {
            var name = validCall.toName ?? ""
            var number = validCall.to ?? ""
            
            durationLabel.text = "\(validCall.duration ?? "00.00")"
            dateLabel.text = "\(validCall.starttime ?? "")"
            
            if validCall.direction?.lowercased().contains("inbound") ?? false {
                icon.image = UIImage(named: "inbound")
                name = validCall.fromName ?? ""
                number = validCall.from ?? ""
            }
            else if validCall.direction?.lowercased().contains("outbound") ?? false {
                    icon.image = UIImage(named: "outbound")
                name = validCall.toName ?? ""
                number = validCall.to ?? ""
            }
            
            nameLabel.text = name.count > 0 ? name : number
            numberLabel.text = name.count > 0 ? number : ""
        }
    }
    
    @IBAction func openURL(_ sender:UIButton) {
        if let url = URL(string: "https://www.google.com") {
            UIApplication.shared.open(url)
        }
    }
}
