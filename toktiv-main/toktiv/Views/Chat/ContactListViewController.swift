//
//  ChatListingViewController.swift
//  toktiv
//
//  Created by Zeeshan Tariq on 10/08/2021.
//

import UIKit
import MBProgressHUD


class ContactListViewController: UIViewController {

    @IBOutlet weak var tableView:UITableView!
    
    var refreshControl = UIRefreshControl()
    
    var contactsList = [ChatUserModel]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        MBProgressHUD.showAdded(to: self.view, animated: true)
        ChatViewModel.shared.getChatUserList( completion: { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.contactsList = response ?? []
            self.contactsList = self.contactsList.filter{ $0.providerCode != StateManager.shared.loginViewModel.userProfile?.providerCode }
            self.tableView.reloadData()
        })
    }
    
    //MARK: - IBActions
    @IBAction func popThisController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc func refresh(_ sender: AnyObject) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        ChatViewModel.shared.getChatUserList( completion: { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.contactsList = response ?? []
            self.contactsList = self.contactsList.filter{ $0.providerCode != StateManager.shared.loginViewModel.userProfile?.providerCode }
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        })
    }
    

}


extension ContactListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return contactsList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ContactTableViewCell.cellForTableView(tableView, atIndexPath: indexPath)
        cell.nameLabel.text = contactsList[indexPath.row].providerName ?? ""
        cell.statusView.backgroundColor = (contactsList[indexPath.row].userOnline ?? false) ? UIColor.green : UIColor.red
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
            controller.toEmpID = contactsList[indexPath.row].empID ?? ""
            controller.toName = contactsList[indexPath.row].providerName ?? ""
            controller.navigation = .Contacts
            self.navigationController?.pushViewController(controller, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
