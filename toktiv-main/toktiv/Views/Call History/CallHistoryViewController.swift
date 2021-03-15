//
//  CallHistoryViewController.swift
//  toktiv
//
//  Created by Developer on 12/11/2020.
//

import UIKit
import MBProgressHUD

protocol CallHistoryNumberSelectionProtocol {
    func didSelectNumber(_ number:String?)
}

class CallHistoryViewController: UIViewController {
    
    @IBOutlet weak var tableView:UITableView!
    
    var observer = StateManager.shared
    let cellIdentifier = "HistotyTableCell"
    var refreshControl = UIRefreshControl()
    var delegate:CallHistoryNumberSelectionProtocol?
    
    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
        
        refreshControl.attributedTitle = NSAttributedString(string: "Pull to refresh")
        refreshControl.addTarget(self, action: #selector(self.refresh(_:)), for: .valueChanged)
        tableView.addSubview(refreshControl)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MBProgressHUD.showAdded(to: self.view, animated: true)
        observer.userHistoryViewModel.getUserCallHistory(providerCode: self.observer.loginViewModel.userProfile?.providerCode ?? "", accessToken: observer.loginViewModel.userAccessToken) { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.observer.userHistoryViewModel.currentCalls.removeAll()
            self.observer.userHistoryViewModel.currentCalls = response ?? []
            self.tableView.reloadData()
        }
    }
    
    //MARK: - Helper
    @objc func refresh(_ sender: AnyObject) {
        observer.userHistoryViewModel.getUserCallHistory(providerCode: self.observer.loginViewModel.userProfile?.providerCode ?? "", accessToken: observer.loginViewModel.userAccessToken) { (response, error) in
            MBProgressHUD.hide(for: self.view, animated: true)
            self.observer.userHistoryViewModel.currentCalls.removeAll()
            self.observer.userHistoryViewModel.currentCalls = response ?? []
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
}


extension CallHistoryViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.observer.userHistoryViewModel.currentCalls.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? HistotyTableCell {
            cell.callRecord = self.observer.userHistoryViewModel.currentCalls[indexPath.row]
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let call = self.observer.userHistoryViewModel.currentCalls[indexPath.row]
        if call.direction?.lowercased().contains("inbound") ?? false {
            self.delegate?.didSelectNumber(call.from)
        }
        else if call.direction?.lowercased().contains("outbound") ?? false {
            self.delegate?.didSelectNumber(call.to)
        }
        else {
            self.delegate?.didSelectNumber(call.to)
        }
    }
}
