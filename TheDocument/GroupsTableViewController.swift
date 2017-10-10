//
//  GroupsTableViewController.swift
//  TheDocument
//

import UIKit

class GroupsTableViewController: BaseTableViewController {

    var selectedGroup:Group?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: "\(UserEvents.groupsRefresh)"), object: nil, queue: nil) { (notification) in
            self.refreshGroups()
        }
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(GroupsTableViewController.refreshGroups), for: .valueChanged)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil)
        self.refreshGroups()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.groupDetailsVCStoryboardIdentifier, let groupDetailsVC = segue.destination as? GroupDetailsViewController {
            guard let group = selectedGroup else { return }
            
            groupDetailsVC.group = group
        } else if segue.identifier == Constants.addGroupStoryboardIdentifier {
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
        }
    }
    
    //MARK: BaseTableVC
    override func rowsCount() -> Int { return currentUser.groups.count }
    override func emptyViewAction()  { performSegue(withIdentifier: Constants.addGroupStoryboardIdentifier, sender: self)}
}

//MARK: UITableView Datasource & delegate
extension GroupsTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedGroup = currentUser.groups[indexPath.row]
        self.performSegue(withIdentifier: Constants.groupDetailsVCStoryboardIdentifier, sender: self)
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentUser.groups.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        let group = currentUser.groups[indexPath.row]

        cell.setup(group)
        if group.state == .invited {
            cell.acceptButton.didTouchUpInside = {_ in self.acceptGroupInvitation(group) }
        } else {
            cell.acceptButton.didTouchUpInside = nil
        }
        
        setImage(id: group.id, forCell: cell, type: "groups")
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        guard indexPath.row >= 0 && indexPath.row < currentUser.groups.count else {
            return nil
        }
        
        let group = currentUser.groups[indexPath.row]
        
        let title = group.state == .own ? Constants.deleteTitle : (!(group.state == .member) ? Constants.rejectTitle : Constants.leaveTitle)
        
        let rowAction = UITableViewRowAction(style: UITableViewRowActionStyle.default, title:  title) { action, index in
            tableView.beginUpdates()
            tableView.deleteRows(at: [index], with: UITableViewRowAnimation.fade)
            currentUser.groups.removeObject(group)
            tableView.endUpdates()
            self.removeGroup(group: group)
        }
        
        rowAction.backgroundColor = .red
        return [rowAction]
    }
}

//MARK: IO
extension GroupsTableViewController {
    
    @objc func refreshGroups() {
        self.startActivityIndicator()
        self.refreshControl?.endRefreshing()
        API().getGroups() { success in
            self.stopActivityIndicator()
            self.refresh()
        }
    }
    
    func acceptGroupInvitation(_ group:Group) {
        API().acceptGroupInvitation(group: group) { success in
            if success {
                var newGroup = group
                newGroup.state = .member
                currentUser.groups.removeObject(newGroup)
                currentUser.groups.append(newGroup)
                self.refresh()
            } else {
                self.refreshGroups()
                self.showAlert(message: Constants.Errors.groupDoesNotExist.rawValue);
            }
        }
    }
    
    func removeGroup(group:Group) {
        self.startActivityIndicator()
        API().removeGroup(group: group){success in
            self.stopActivityIndicator()
            if !success { self.showAlert(message: Constants.Errors.defaultError.rawValue) }
            self.refresh()
        }
        
    }
}
