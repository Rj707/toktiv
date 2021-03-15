//
//  PatientsViewController.swift
//  toktiv
//
//  Created by Developer on 02/12/2020.
//

import UIKit
import NotificationBannerSwift

protocol PatientSelectionProtocol {
    func patientDidSelected(_ patient:Patient, isCall:Bool)
}

class PatientsViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView! {
        didSet {
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
    }
    
    let cellIdentifier = "PatientCell"
    var currentSearchedPatients:[Patient] = []
    var deletgate:PatientSelectionProtocol?
    
    //MARK: - View LifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
    }
    
    //MARK: - IBActions
    
    @IBAction func popThisController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func callButtonPressed(sender:UIButton) {
        let patient = self.currentSearchedPatients[sender.tag]
        guard let phone = patient.cellNumber, !phone.isEmpty else {
            NotificationBanner(title: nil, subtitle: "Patient phone number is not valid", leftView: nil, rightView: nil, style: .warning, colors: nil).show()
            return
        }
        self.deletgate?.patientDidSelected(patient, isCall: true)
        self.dismiss(animated: true, completion: nil)
    }
    
    @objc func smsButtonPressed(sender:UIButton) {
        let patient = self.currentSearchedPatients[sender.tag]
        guard let phone = patient.cellNumber, !phone.isEmpty else {
            NotificationBanner(title: nil, subtitle: "Patient phone number is not valid", leftView: nil, rightView: nil, style: .warning, colors: nil).show()
            return
        }
        self.dismiss(animated: true) {
            self.deletgate?.patientDidSelected(patient, isCall: false)
        }
    }
}

extension PatientsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentSearchedPatients.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? PatientCell {
            cell.currentPatient = self.currentSearchedPatients[indexPath.row]
            cell.callButton.tag = indexPath.row
            cell.smsButton.tag = indexPath.row
            
            cell.callButton.addTarget(self, action: #selector(self.callButtonPressed(sender:)), for: .touchUpInside)
            cell.smsButton.addTarget(self, action: #selector(smsButtonPressed(sender:)), for: .touchUpInside)
            
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
