//
//  CurrentLocationViewController.swift
//  MyLocations
//
//  Created by Zhaofei Yin on 14.11.17.
//  Copyright © 2017 Zhaofei Yin. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController : UIViewController
                                    , CLLocationManagerDelegate{
    
    // IB Outlet
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    // Other data members
    let locationManager = CLLocationManager()
    
    
    // UI callbacks
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if (authStatus == .denied || authStatus == .restricted) {
            showLocationServicesDeniedAlert()
            return
        }
        
        if authStatus == .notDetermined {
            locationManager.requestWhenInUseAuthorization()
        }
        
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("didFailWithError \(error)")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Helper functions
    func showLocationServicesDeniedAlert() {
        let alert = UIAlertController(title: "Location Services Disabled",
                                      message: "Please enable location servies for this app in Settings",
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertActionStyle.default, handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }


}

