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
    let mLocationManager = CLLocationManager()
    
    var mLocation: CLLocation?
    var mUpdatingLocation = false
    var mLastLocationError: Error?
    
    
    // UI callbacks
    @IBAction func getLocation() {
        let authStatus = CLLocationManager.authorizationStatus()
        
        if (authStatus == .denied || authStatus == .restricted) {
            showLocationServicesDeniedAlert()
            return
        }
        
        if authStatus == .notDetermined {
            mLocationManager.requestWhenInUseAuthorization()
        }
        
        mLocationManager.delegate = self
        mLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        mLocationManager.startUpdatingLocation()
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("didFailWithError \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            return
        }
        
        mLastLocationError = error
        
        stopLocationManager()
        updateLabels()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let newLocation = locations.last!
        mLocation = newLocation
        
        updateLabels()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateLabels()
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
    
    func updateLabels() {
        if let location = mLocation {
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            tagButton.isHidden = false
            messageLabel.text = ""
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            tagButton.isHidden = true
            messageLabel.text = "Tap 'Get My Location' to Start"
            
            let statusMessage: String
            if let error = mLastLocationError as? NSError {
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue {
                    statusMessage = "Location Services Disabled"
                } else {
                    statusMessage = "Error Getting Location"
                }
            } else if !CLLocationManager.locationServicesEnabled() {
                statusMessage = "Location Services Disabled"
            } else if mUpdatingLocation {
                statusMessage = "Searching..."
            } else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            
            messageLabel.text = statusMessage
        }
    }
    
    func stopLocationManager() {
        if mUpdatingLocation {
            mLocationManager.stopUpdatingLocation()
            mLocationManager.delegate = nil
            mUpdatingLocation = false
        }
    }


}

