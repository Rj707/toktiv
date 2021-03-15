//
//  PatientCell.swift
//  toktiv
//
//  Created by Developer on 02/12/2020.
//

import UIKit

class PatientCell: UITableViewCell {

    var currentPatient:Patient?
    
    @IBOutlet weak var nameLabel:UILabel!
    @IBOutlet weak var emailLabel:UILabel!
    @IBOutlet weak var phoneLabel:UILabel!
    
    @IBOutlet weak var callButton:UIButton!
    @IBOutlet weak var smsButton:UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let validPatient = self.currentPatient {
            self.nameLabel.text = validPatient.name ?? ""
            self.emailLabel.text = validPatient.email ?? ""
            let countryCode = validPatient.country ?? ""
            self.phoneLabel.text = "\(countryCode)\(validPatient.cellNumber ?? "")"
        }
    }
}
