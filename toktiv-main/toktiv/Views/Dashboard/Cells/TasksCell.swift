//
//  TasksCell.swift
//  toktiv
//
//  Created by Developer on 03/12/2020.
//

import UIKit

class TasksCell: UITableViewCell {

    var currentTask:ActiveTask?
    @IBOutlet weak var nameLabel:UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        
        if let task = self.currentTask {
            self.nameLabel.text = task.taskGroupName ?? task.cellNumber ?? ""
        }
    }
}
