//
//  IntroductionViewController.swift
//  TheDocument
//


import Foundation
import Firebase
import UIKit


class IntroductionViewController : UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var pageControl: UIPageControl!
    
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    var currentPage:Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.delegate = self
        //startActivityIndicator()
        pageControl.currentPageIndicatorTintColor = Constants.Theme.mainColor
        pageControl.pageIndicatorTintColor = Constants.Theme.authButtonNormalBorderColor
        
        Database.database().reference().child("introduction").observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let introDict = snapshot.value as? [String : [String:String] ] {
                var offset:CGFloat = 0
                if introDict.keys.count <= 1 {
                    self.pageControl.isHidden = true
                } else {
                    self.pageControl.numberOfPages = introDict.keys.count
                }
                
                for key in introDict.keys {
                    
                    guard let screen = introDict[key], let image = screen["image"] , let title = screen["title"], let body  = screen["body"] else { break }
                    
                    let page = self.storyboard?.instantiateViewController(withIdentifier: Constants.introductionPageVCStoryboardIdentifier) as! IntroPageViewController
                    
                    page.imageURLString = "\(Constants.FIRStoragePublicURL)\(image)?alt=media"
                    page.titleString = title
                    page.bodyString = body
                    
                    page.view.frame = self.view.frame.offsetBy(dx: offset * page.view.frame.width, dy: 0.0)
                    
                    self.addChildViewController(page)
                    self.scrollView.addSubview(page.view)
                    page.didMove(toParentViewController: self)
                    
                    offset += 1
                }
                
                self.scrollView.contentSize = CGSize(width: self.view.frame.size.width * offset, height: self.view.frame.size.height - 64)
                self.scrollView.isPagingEnabled = true
                //self.stopActivityIndicator()
            }
        })
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(closeIntro))
        tap.numberOfTapsRequired = 2
        view.addGestureRecognizer(tap)
    }
    
    @objc func closeIntro() {
        UserDefaults.standard.set(true, forKey: Constants.shouldSkipIntroKey)
        self.dismiss(animated: true, completion: nil)
    }
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    @IBAction func nextPage(_ sender: UIButton) {
        
        guard (currentPage < pageControl.numberOfPages - 1) else { closeIntro(); return }
        
        currentPage += 1
        var frame = scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(currentPage)
        scrollView.scrollRectToVisible(frame, animated: true)
        
    }
    
    @IBAction func prevPage(_ sender: UIButton) {
        
        guard currentPage > 0 else { return }
        
        currentPage -= 1
        var frame = scrollView.frame
        frame.origin.x = frame.size.width * CGFloat(currentPage)
        scrollView.scrollRectToVisible(frame, animated: true)
    }
}

extension IntroductionViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let pageWidth = scrollView.frame.size.width
        let page = Int(floor((scrollView.contentOffset.x * 2.0 + pageWidth) / (pageWidth * 2.0)))
        
        // Update the currentPage
        self.pageControl.currentPage = page
        currentPage = self.pageControl.currentPage
        
        backButton.isHidden = page == 0
        if page == self.pageControl.numberOfPages - 1 {
            nextButton.setImage(nil, for: .normal)
            nextButton.setTitle("Done", for: .normal)
        } else {
            nextButton.setTitle("", for: .normal)
            nextButton.setImage(UIImage(named: "ArrowForward"), for: .normal)
        }
    }
}
