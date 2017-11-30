//
//  BaseTableViewController.swift
//  TheDocument
//

import UIKit

class BaseTableViewController: UITableViewController {
    
    var type:String = ""
    let emptyViewTag = 919547
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.tintColor = .white
        
        self.navigationController?.navigationBar.backIndicatorImage = UIImage(named:"ArrowBack")
        self.navigationController?.navigationBar.backIndicatorTransitionMaskImage = UIImage(named:"ArrowBack")
        
        let nib = UINib(nibName: "ItemCell", bundle: nil)
        tableView.register(nib, forCellReuseIdentifier: "ItemTableViewCell")
        
        tableView.contentInset    = UIEdgeInsets(top: 0, left: 0, bottom: 70.0, right: 0)
        tableView.tableFooterView = UIView()
    }
    
    func reloadRow(at indexPath: IndexPath) {
        if tableView.indexPathsForVisibleRows?.contains(indexPath) == true {
            tableView.reloadRows(at: [indexPath], with: .none)
        }
    }
    
    override func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        let header = view as! UITableViewHeaderFooterView
        header.textLabel?.font = UIFont(name: "OpenSans", size: 11)
        header.textLabel?.textColor = UIColor.lightGray
    }
    
    func setImage(id: String, forCell cell: ItemTableViewCell, type: String = "photos") {
        guard let challengerId = id.components(separatedBy: ",").first else { return }
        
        if let imageData = downloadedImages[challengerId] {
            cell.setImage(imgData: imageData)
        } else {
            cell.setImageLoading()
            appDelegate.downloadImageFor(id: id, section: type) { success in
                DispatchQueue.main.sync {
                    guard success, let ip = self.tableView.indexPath(for: cell) else {
                        cell.setGenericImage()
                        return
                    }
                    self.reloadRow(at: ip)
                }
            }
        }
    }
    
    func rowsCount() -> Int { return 0 }
    
    func refresh(_ set:IndexSet? = nil) {
        DispatchQueue.main.async {
            if let set = set {
                self.tableView.reloadSections(set, with: .fade)
            } else {
                self.tableView.reloadData()
            }
            
            print("There are \(self.rowsCount()) rows to display")
            
            if self.rowsCount() > 0 {
                self.tableView.tableFooterView?.isHidden = false
                self.view.viewWithTag(self.emptyViewTag)?.removeFromSuperview()
                
            } else {
                self.tableView.tableFooterView?.isHidden = true
                if let emptyView = self.view.viewWithTag(self.emptyViewTag) {
                    self.view.addSubview(emptyView)
                    self.view.bringSubview(toFront: emptyView)
                } else {
                    self.view.addSubview(self.emptyView())
                    self.view.bringSubview(toFront: self.emptyView())
                }
            }
        }
    }
    
    func emptyView() -> UIView {
        
        let emptyNib = Bundle.main.loadNibNamed("Empty", owner: nil, options: nil)
        guard let emptyView = emptyNib?.first as? Empty,
            let emptySection = Constants.zeroRecordsData[String(describing: Swift.type(of: self))] ,
            let emptySectionOffset = emptySection["offset"] as? CGFloat,
            let emptySectionTitle = emptySection["title"] as? String,
            let emptySecionSubTitle = emptySection["subtitle"] as? String,
            let emptySecionButtonTitle = emptySection["buttonTitle"] as? String
            else {
                return UIView()
        }
        
        emptyView.frame = CGRect(x: 0, y: emptySectionOffset, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
        emptyView.titleLabel.text = emptySectionTitle
        emptyView.subtitleLabel.text = emptySecionSubTitle
        emptyView.submitButton.addTarget(self, action: #selector(BaseTableViewController.emptyViewAction), for: .touchUpInside)
        emptyView.submitButton.setTitle(emptySecionButtonTitle, for: .normal)
        emptyView.tag = emptyViewTag
        return emptyView
    }
    
    @objc func emptyViewAction() {}
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}
