//
//  ActiveTasksViewController.swift
//  toktiv
//
//  Created by Developer on 03/12/2020.
//

import UIKit

protocol ActiveTasksSelectionProtocol {
    func taskDidSelected(_ tasks:ActiveTask)
}

class ActiveTasksViewController: UIViewController, UISearchBarDelegate {
    
    @IBOutlet weak var searchBar:UISearchBar!
    @IBOutlet weak var tableView:UITableView! {
        didSet {
            self.tableView.delegate = self
            self.tableView.dataSource = self
        }
    }
    
    let cellIdentifier = "TasksCell"
    var activeTaskList:[ActiveTask] = []
    var currentTaskToShow:[ActiveTask] = []
    var deletgate:ActiveTasksSelectionProtocol?

    //MARK: - View Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.currentTaskToShow = self.activeTaskList
        self.tableView.register(UINib(nibName: cellIdentifier, bundle: nil), forCellReuseIdentifier: cellIdentifier)
    }
    
    //MARK: - IBActions
    
    @IBAction func popThisController() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    //MARK: - SearchBar Delegate
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text == "" {
            currentTaskToShow = self.activeTaskList
        }
        else {
            currentTaskToShow = self.activeTaskList.filter { (task) -> Bool in
                return (task.taskGroupName?.lowercased().contains(searchBar.text?.lowercased() ?? "") ?? false)
            }
        }
        
        tableView.reloadData()
    }
    
}


extension ActiveTasksViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.currentTaskToShow.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = self.tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? TasksCell {
            cell.currentTask = self.currentTaskToShow[indexPath.row]
            return cell
        }
        
        return UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        let task = self.currentTaskToShow[indexPath.row]

        self.deletgate?.taskDidSelected(task)
        self.dismiss(animated: true, completion: nil)
    }
}
