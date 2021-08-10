//
//  ContactTableViewCell.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 10/08/2021.
//

import UIKit

class ContactTableViewCell: UITableViewCell {

    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var statusView: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    static func cellForTableView(_ tableView: UITableView, atIndexPath indexPath: IndexPath) -> ContactTableViewCell {
         let identifier = "ContactTableViewCell"
         tableView.register(UINib(nibName:"ContactTableViewCell", bundle: nil), forCellReuseIdentifier: identifier)
         let cell = tableView.dequeueReusableCell(withIdentifier: identifier, for: indexPath) as! ContactTableViewCell
         return cell
     }
}
