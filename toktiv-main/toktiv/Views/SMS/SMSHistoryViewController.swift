//
//  SMSHistoryViewController.swift
//  toktiv
//
//  Created by Developer on 14/11/2020.
//

import UIKit
import MBProgressHUD

class SMSHistoryViewController: UIViewController, NewMessageConversationDelegate {

    @IBOutlet weak var tableView:UITableView!
    
    var observer = StateManager.shared
    let cellIdentifier = "SMSHistoryCell"
    var refreshControl = UIRefreshControl()

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        
        
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let providerCode = self.observer.loginViewModel.userProfile?.providerCode {
            MBProgressHUD.showAdded(to: self.view, animated: true)
            observer.userHistoryViewModel.getUserSMSHistory(providerCode: providerCode, from: "", to: "", type: "smshistory") { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.observer.userHistoryViewModel.currenSMSs = response ?? []
                self.tableView.reloadData()
            }
        }
    }
    
    //MARK: - IBActions
    @IBAction func popThisController() {
        self.navigationController?.popViewController(animated: true)
    }
    
    @IBAction func newMessageView() {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "NewMessageViewController") as? NewMessageViewController {
            controller.delegate = self
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    @objc func refresh(_ sender: AnyObject) {
        if let providerCode = self.observer.loginViewModel.userProfile?.providerCode {
            observer.userHistoryViewModel.getUserSMSHistory(providerCode: providerCode, from: "", to: "", type: "smshistory") { (response, error) in
                MBProgressHUD.hide(for: self.view, animated: true)
                self.observer.userHistoryViewModel.currenSMSs.removeAll()
                self.observer.userHistoryViewModel.currenSMSs = response ?? []
                self.refreshControl.endRefreshing()
                self.tableView.reloadData()
            }
        }
        else {
            self.refreshControl.endRefreshing()
        }
    }
    
    //MARK: - NewMessageConversationDelegate
   
    func newMessageCreated(_ selectedChat: HistoryResponseElement) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ConvesationViewController") as? ConvesationViewController {
            controller.selectedChat = selectedChat
            self.navigationController?.pushViewController(controller, animated: true)
        }
    }
}

extension SMSHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.observer.userHistoryViewModel.currenSMSs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? SMSHistoryCell {
            cell.smsRecord = self.observer.userHistoryViewModel.currenSMSs[indexPath.row]
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ConvesationViewController") as? ConvesationViewController {
            controller.selectedChat = self.observer.userHistoryViewModel.currenSMSs[indexPath.row]
            self.navigationController?.pushViewController(controller, animated: true)
        }
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}
