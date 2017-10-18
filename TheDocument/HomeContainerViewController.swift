//
//  HomeContainerViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 10/18/17.
//  Copyright © 2017 Refer To The Document. All rights reserved.
//

import UIKit

class HomeContainerViewController: UIViewController {
    
    enum SegueIdentifiers: String {
        case overview, friends, groups, settings
    }
    
    var currentSegueIdentifier: String = "embed_overview"

    override func viewDidLoad() {
        super.viewDidLoad()
        currentSegueIdentifier = "embed_\(SegueIdentifiers.overview)"
        performSegue(withIdentifier: currentSegueIdentifier, sender: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if self.childViewControllers.count > 0 {
            self.swapViewControllers(from: childViewControllers[0], to: segue.destination)
        } else {
            self.swapViewControllers(from: nil, to: segue.destination)
        }
    }
    
    func swapViewControllers(from: UIViewController?, to: UIViewController) {
        if let childToRemove = from {
            removeChild(vc: childToRemove)
        }
        addChild(vc: to)
    }
    
    func addChild(vc: UIViewController) {
        self.addChildViewController(vc)
        vc.view.frame = self.view.frame
        self.view.addSubview(vc.view)
        vc.didMove(toParentViewController: self)
    }
    
    func removeChild(vc: UIViewController) {
        vc.willMove(toParentViewController: nil)
        vc.view.removeFromSuperview()
        vc.removeFromParentViewController()
    }
    
    public func loadChildView(identifier: String) {
        self.performSegue(withIdentifier: identifier, sender: nil)
    }
}
