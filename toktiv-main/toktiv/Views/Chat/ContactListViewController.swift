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
    @IBOutlet weak var searchBar:UISearchBar! {
        didSet {
            self.searchBar.delegate = self
        }
    }
    
    @IBOutlet weak var cancelButton:UIButton!

    
    var refreshControl = UIRefreshControl()
    
    var contactsList = [ChatUserModel]()
    var filterArray = [ChatUserModel]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)

    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let defaults = UserDefaults(suiteName: "group.com.drcurves.toktiv")

        if let contactListData = defaults?.data(forKey: AppConstants.CONTACT_LIST) {
            if let list = try? JSONDecoder().decode([ChatUserModel].self, from: contactListData) {
                self.contactsList = list
                self.contactsList = self.contactsList.filter{ $0.providerCode != StateManager.shared.loginViewModel.userProfile?.providerCode }
                self.filterArray = self.contactsList
                self.searchBar.isHidden = !(self.filterArray.count > 0)
                self.tableView.reloadData()
                
            }
        }
        else
        {
            MBProgressHUD.showAdded(to: self.view, animated: true)
        }

        ChatViewModel.shared.getChatUserList( completion: { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.contactsList = response ?? []
            self.contactsList = self.contactsList.filter{ $0.providerCode != StateManager.shared.loginViewModel.userProfile?.providerCode }
            self.filterArray = self.contactsList
            self.searchBar.isHidden = !(self.filterArray.count > 0)
            self.tableView.reloadData()
        })
    }
    
    //MARK: - IBActions
    @IBAction func popThisController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func cancelButtonTouched() {
        searchBar.text = ""
        searchBar.resignFirstResponder()
        self.filterArray = self.contactsList
        self.tableView.reloadData()
        cancelButton.isHidden = true
    }
    
    @objc func refresh(_ sender: AnyObject) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        ChatViewModel.shared.getChatUserList( completion: { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.contactsList = response ?? []
            self.contactsList = self.contactsList.filter{ $0.providerCode != StateManager.shared.loginViewModel.userProfile?.providerCode }
            self.refreshControl.endRefreshing()
            self.filterArray = self.contactsList
            self.searchBar.isHidden = !(self.filterArray.count > 0)
            self.tableView.reloadData()
        })
    }
    

}


extension ContactListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filterArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = ContactTableViewCell.cellForTableView(tableView, atIndexPath: indexPath)
        cell.nameLabel.text = filterArray[indexPath.row].providerName ?? ""
        cell.statusView.backgroundColor = (filterArray[indexPath.row].userOnline ?? false) ? UIColor.green : UIColor.red
        
        switch filterArray[indexPath.row].TwilioStatus ?? ""
        {
            case "Offline":
                cell.twilioStatusImage.setImageTintColor(UIColor.hexStringToUIColor(hex: "F3FF63")) // Yellowish // #F3FF63
                cell.twilioStatusImage.setImageTintColor(UIColor.red) // red
                break
            case "Idle":
                cell.twilioStatusImage.setImageTintColor(UIColor.hexStringToUIColor(hex: "35BF31")) // Green // #35BF31
                cell.twilioStatusImage.setImageTintColor(UIColor.green) // green
                break
            case "Online":
                cell.twilioStatusImage.setImageTintColor(UIColor.hexStringToUIColor(hex: "35BF31")) // Green // #35BF31
                cell.twilioStatusImage.setImageTintColor(UIColor.green) // green
                break
            case "Busy":
                cell.twilioStatusImage.setImageTintColor(UIColor.hexStringToUIColor(hex: "FF0101")) // Red // #FF0101
                cell.twilioStatusImage.setImageTintColor(UIColor.orange) // orange
                break
            case "Automated Call":
                cell.twilioStatusImage.setImageTintColor(UIColor.hexStringToUIColor(hex: "000000"))
                break
            default:
                cell.twilioStatusImage.setImageTintColor(UIColor.hexStringToUIColor(hex: "000000"))
                print("default:\(filterArray[indexPath.row].TwilioStatus ?? "")")
        }
        
//        TwilioStatus = "Offline" : "Red"
//        TwilioStatus = "Online" : "Green"
//        TwilioStatus = "Busy" : "Orange"
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 81
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ChatViewController") as? ChatViewController {
            controller.toEmpID = filterArray[indexPath.row].empID ?? ""
            controller.toName = filterArray[indexPath.row].providerName ?? ""
            controller.navigation = .Contacts
            cancelButtonTouched()
            self.navigationController?.pushViewController(controller, animated: true)
        }

        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ContactListViewController : UISearchBarDelegate
{
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        self.performSearch(input: searchBar.text ?? "")
        searchBar.resignFirstResponder()
    }
    
//    func searchBarShouldBeginEditing(_ searchBar: UISearchBar) -> Bool {
//        cancelButton.isHidden = !(searchBar.text?.count ?? 0 > 0)
//        return true
//    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        self.performSearch(input: searchBar.text ?? "")
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        self.performSearch(input: searchBar.text ?? "")
        cancelButton.isEnabled = searchBar.text?.count ?? 0 > 0
        cancelButton.isHidden = !(searchBar.text?.count ?? 0 > 0)
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()
    }
    
    func searchBar(_ searchBar: UISearchBar, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        
        return true
    }
    
    func performSearch(input:String)
    {
        if input == ""
        {
            self.filterArray = self.contactsList
            self.tableView.reloadData()
        }
        else
        {
            self.filterArray = self.contactsList.filter{($0.providerName)!.localizedCaseInsensitiveContains(input)}
            
            self.tableView.reloadData()
        }
    }

}
