//
//  OverviewTableViewController.swift
//  TheDocument
//

import UIKit
import Firebase

class OverviewTableViewController: BaseTableViewController {
    
    @IBOutlet weak var challengesTabButton: TabButton!
    @IBOutlet weak var leaderBoardTabButton: TabButton!
    
    var leaderboardMode = false
    var leaderboardDatasource = [TDUser]()
    
    var selectedIP:IndexPath? = nil
    var challengesReady: Bool = false
    
    var futureChallenges: [Challenge] = [Challenge]()
    var currentChallenges: [Challenge] = [Challenge]()
    var pastChallenges: [Challenge] = [Challenge]()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Tableview setup
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 80
        
        let logoImage = UIImageView(frame: CGRect(x: 0, y: 0, width: 38, height: 38))
        logoImage.contentMode = .scaleAspectFit
        logoImage.image = UIImage(named: "LogoSmall")
        self.navigationItem.titleView = logoImage
        
        refreshControl = UIRefreshControl()
        refreshControl?.addTarget(self, action: #selector(OverviewTableViewController.refreshChallenges), for: .valueChanged)
        challengesTabButton.isChecked = false
        leaderBoardTabButton.isChecked = !challengesTabButton.isChecked
        leaderboardMode = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if !challengesReady{
            self.refreshChallenges()
        }
        buildLeaderboard()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil)
    }
    
    override func shouldPerformSegue(withIdentifier identifier: String, sender: Any?) -> Bool {
        if identifier == Constants.challengeDetailsStoryboardIdentifier{
            return selectedIP != nil
        }
        
        return true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == Constants.challengeDetailsStoryboardIdentifier, let destVC = segue.destination as? ChallengeDetailsViewController {
             let selectedIndexPath = selectedIP ?? IndexPath()
            destVC.challenge = selectedIndexPath.section  == 0 ? futureChallenges[selectedIndexPath.row] : ( selectedIndexPath.section == 1 ? currentChallenges[selectedIndexPath.row] : pastChallenges[selectedIndexPath.row] )
        
        } else if segue.identifier == "show_user_profile", let profileVC = segue.destination as? HeadToHeadViewController, let friend = sender as? TDUser {            
            profileVC.playerTwo = friend
        }
    }
    
    override func rowsCount() -> Int { return !leaderboardMode ? futureChallenges.count + currentChallenges.count + pastChallenges.count : leaderboardDatasource.count }
    
    override func emptyViewAction() { homeVC?.performSegue(withIdentifier: Constants.newChallengeStoryboardSegueIdentifier, sender: self) }
}

//MARK: IB
extension OverviewTableViewController {
    @IBAction func challengesTapped(_ sender: TabButton? = nil) {
        leaderBoardTabButton.isChecked = false
        challengesTabButton.isChecked = !leaderBoardTabButton.isChecked
        leaderboardMode = false
        refresh()
    }
    @IBAction func leaderBoardTapped(_ sender: TabButton? = nil) {
        challengesTabButton.isChecked = false
        leaderBoardTabButton.isChecked = !challengesTabButton.isChecked
        leaderboardMode = true
        buildLeaderboard()
    }
}

//MARK: UITableView delegate & datasource
extension OverviewTableViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        return leaderboardMode ? 1 : 3
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard leaderboardMode == false else { return leaderboardDatasource.count }
        
        switch section {
        case 0:
            return futureChallenges.count
        case 1:
            return currentChallenges.count
        case 2:
            return pastChallenges.count
        default: return 0
        }
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ItemTableViewCell") as! ItemTableViewCell
        let row = indexPath.row
        let section = indexPath.section
        
        if !leaderboardMode {
            let item = section == 0 ? futureChallenges[row] : (section == 1 ? currentChallenges[row] : pastChallenges[row] )
            cell.setup(item)
            
            if let uid = item.competitorId().components(separatedBy: ",").first {
                setImage(id: uid, forCell: cell)
            }

        } else {
            let lbFriend = leaderboardDatasource[indexPath.row]
            cell.setup(lbFriend, cellId: indexPath.row + 1)
            setImage(id: lbFriend.uid, forCell: cell)
            
            if let wins = lbFriend.record.totalWins, let losses = lbFriend.record.totalLosses {
                cell.bottomLabel.text = "\(wins)-\(losses)"
            } else {
                cell.bottomLabel.text = "0-0"
                //setUserRecord(user: lbFriend, cell: cell)
            }
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard !leaderboardMode else { return nil }
        
        if (section == 0 && futureChallenges.count > 0) {
            return Constants.futureChallengesTitle.uppercased()
        } else if (section == 1 && currentChallenges.count > 0) {
            return Constants.currentChallengesTitle.uppercased()
        } else if (section == 2 && pastChallenges.count > 0) {
            return Constants.pastChallengesTitle.uppercased()
        } else {
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if !leaderboardMode {
            selectedIP = indexPath
            self.performSegue(withIdentifier: Constants.challengeDetailsStoryboardIdentifier, sender: self)
            
        } else {
            let lbFriend = leaderboardDatasource[indexPath.row]
            self.performSegue(withIdentifier: "show_user_profile", sender: lbFriend)
        }
    }
}

//MARK: Helpers
extension OverviewTableViewController {
    
    @objc func refreshChallenges() {
        currentUser.getChallenges() {
            self.challengesReady = true
            self.futureChallenges = currentUser.challenges.filter { $0.status == 0 }
            self.currentChallenges = currentUser.challenges.filter { $0.status == 1 }
            self.pastChallenges = currentUser.challenges.filter { $0.status == 2 }.completionSorted()
            self.tableView.reloadData()
            
            currentUser.getFriends() {
                self.refreshControl?.endRefreshing()
                self.refresh()
            }
        }
    }
    
    func buildLeaderboard() {
        leaderboardDatasource = (currentUser.friends + [currentUser]).sortByWilsonRanking()
        if leaderboardMode {
            refresh()
        }
    }
    
}

