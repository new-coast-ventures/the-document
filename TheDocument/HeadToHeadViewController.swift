//
//  HeadToHeadViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 10/4/17.
//  Copyright © 2017 Mruvka. All rights reserved.
//

import UIKit
import Firebase

class HeadToHeadViewController: BaseViewController {

    @IBOutlet weak var playerOneImageView: UIImageView!
    @IBOutlet weak var playerOneNameLabel: UILabel!
    @IBOutlet weak var playerOneWinsLabel: UILabel!
    @IBOutlet weak var playerOneWinPercentageLabel: UILabel!
    
    @IBOutlet weak var playerTwoImageView: UIImageView!
    @IBOutlet weak var playerTwoNameLabel: UILabel!
    @IBOutlet weak var playerTwoWinsLabel: UILabel!
    @IBOutlet weak var playerTwoWinPercentageLabel: UILabel!
    
    @IBOutlet weak var versusOuterContainer: UIView!
    @IBOutlet weak var versusInnerContainer: UIView!
    @IBOutlet weak var versusLabel: UILabel!
    
    @IBOutlet weak var startChallengeButton: UIButton!
    
    var playerTwo: TDUser!
    var playerOneWins = 0
    var playerTwoWins = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Head-to-Head"
        
        versusOuterContainer.layer.cornerRadius = 50
        versusInnerContainer.layer.cornerRadius = 35
        versusLabel.layer.cornerRadius = 20
        
        if let competitorData = UserDefaults.standard.dictionary(forKey: playerTwo.uid) as? [String: Int] {
            playerOneWins = competitorData["wins"] ?? 0
            playerTwoWins = competitorData["losses"] ?? 0
        }
        
        setupPlayerOne()
        setupPlayerTwo()
        setupPieChart()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.hideToolbar)"), object: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "\(UserEvents.showToolbar)"), object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    func setupPlayerOne() {
        let playerOne = currentUser
        playerOneNameLabel.text = playerOne.name.firstNameAndLastInitial()
        playerOneNameLabel.textColor = Constants.Theme.mainColor
        playerOneWinsLabel.text = "\(playerOneWins)"
        playerOneWinsLabel.textColor = Constants.Theme.mainColor
        playerOneWinPercentageLabel.text = winPercentageString()
        playerOneImageView.loadAvatar(_for: playerOne)
    }
    
    func setupPlayerTwo() {
        playerTwoNameLabel.text = playerTwo.name.firstNameAndLastInitial()
        playerTwoNameLabel.textColor = Constants.Theme.buttonBGColor
        playerTwoWinsLabel.text = "\(playerTwoWins)"
        playerTwoWinsLabel.textColor = Constants.Theme.buttonBGColor
        playerTwoWinPercentageLabel.text = winPercentageString(you: false)
        playerTwoImageView.loadAvatar(_for: playerTwo)
    }
    
    func setupPieChart() {
        let p1Color = Constants.Theme.mainColor
        let p2Color = Constants.Theme.buttonBGColor
        let centrePointOfChart = CGPoint(x: 35, y: 35)
        
        let p1Angle = CGFloat((winPercentage(p1: playerOneWins, p2: playerTwoWins) * 360 / 100) + 91)
        
        let piePieces = [
            (UIBezierPath(circleSegmentCenter: centrePointOfChart, radius: 35, startAngle: 90, endAngle: p1Angle), p1Color),
            (UIBezierPath(circleSegmentCenter: centrePointOfChart, radius: 35, startAngle: p1Angle, endAngle: 90), p2Color)]
        
        let pie = pieChart(pieces: piePieces, viewRect: CGRect(x: 0, y: 0, width: 70, height: 70))
        
        // Add pie chart
        self.versusInnerContainer.insertSubview(pie, at: 0)
    }
    
    func winPercentageString(you: Bool = true) -> String {
        let p = you ? winPercentage(p1: playerOneWins, p2: playerTwoWins) : winPercentage(p1: playerTwoWins, p2: playerOneWins)
        return "\(p)% WINS"
    }
    
    func winPercentage(p1: Int, p2: Int) -> Int {
        let numerator = CGFloat(p1)
        let denominator = CGFloat(p1 + p2)
        
        if denominator > 0 {
            return Int(100 * (numerator / denominator))
        } else {
            return 0
        }
    }

    @IBAction func startChallengeButtonPressed(_ sender: Any) {
        if let newChallengeNavVC = self.storyboard?.instantiateViewController(withIdentifier: "NewChallengeNavVC") as? UINavigationController, let newChallengeVC = newChallengeNavVC.viewControllers.first as? NewChallengeViewController {
            newChallengeVC.toId = playerTwo.uid
            self.present(newChallengeNavVC, animated: true, completion: nil)
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

extension String {
    func firstNameAndLastInitial() -> String {
        if let range = self.rangeOfCharacter(from: .whitespaces), !range.isEmpty {
            return String(self.prefix(through: range.upperBound))
        } else {
            return self
        }
    }
}

extension CGFloat {
    func radians() -> CGFloat {
        let b = .pi * self / 180.0
        return b
    }
}

extension UIBezierPath {
    convenience init(circleSegmentCenter center:CGPoint, radius:CGFloat, startAngle:CGFloat, endAngle:CGFloat)
    {
        self.init()
        self.move(to: CGPoint(x: center.x, y: center.y))
        self.addArc(withCenter: center, radius: radius, startAngle: startAngle.radians(), endAngle: endAngle.radians(), clockwise: true)
        self.close()
    }
}

func pieChart(pieces: [(UIBezierPath, UIColor)], viewRect: CGRect) -> UIView {
    var layers = [CAShapeLayer]()
    for p in pieces {
        let layer = CAShapeLayer()
        layer.path = p.0.cgPath
        layer.fillColor = p.1.cgColor
        layer.strokeColor = UIColor.white.cgColor
        layers.append(layer)
    }
    let view = UIView(frame: viewRect)
    for l in layers {
        view.layer.addSublayer(l)
    }
    return view
}
