//
//  IntroLocationViewController.swift
//  TheDocument
//
//  Created by Scott Kacyn on 1/25/18.
//  Copyright © 2018 Refer To The Document. All rights reserved.
//

import UIKit
import CoreLocation

class IntroLocationViewController: UIViewController {
    @IBOutlet weak var button: UIButton!
    let locationManager = CLLocationManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func buttonTapped(_ sender: Any) {
        self.enableBasicLocationServices()
    }
    
    func closeModal() {
        UserDefaults.standard.set(true, forKey: "shouldSkipLocation")
        UserDefaults.standard.synchronize()
        self.dismiss(animated: true, completion: nil)
    }
}

// Location Management
extension IntroLocationViewController: CLLocationManagerDelegate {
    
    func enableBasicLocationServices() {
        locationManager.delegate = self
        switch CLLocationManager.authorizationStatus() {
        case .notDetermined:
            // Request when-in-use authorization initially
            locationManager.requestWhenInUseAuthorization()
            break
            
        case .restricted, .denied:
            // Disable location features
            closeModal()
            break
            
        case .authorizedWhenInUse, .authorizedAlways:
            // Enable location features
            closeModal()
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        closeModal()
    }
}
