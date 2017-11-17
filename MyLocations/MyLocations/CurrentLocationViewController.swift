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
    
    var mGeoCoder = CLGeocoder()
    var mPlacemark: CLPlacemark?
    var mPerformingReverseGeocoding = false
    var mLastGeocodingError: Error?
    
    var mTimer: Timer?
    
    
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
        
        if mUpdatingLocation {
            stopLocationManager()
        } else {
            mLocation = nil
            mLastLocationError = nil
            mPlacemark = nil
            mLastGeocodingError = nil
            
            startLocationManager()
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error){
        print("didFailWithError: \(error)")
        
        if (error as NSError).code == CLError.locationUnknown.rawValue {
            print("didFailWithError: CLError.locationUnknown")
            return
        }
        
        mLastLocationError = error
        
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]) {
        
        let newLocation = locations.last!
        print("*** didUpdateLocations: \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5 {
            print("*** didUpdateLocations: timeIntervalSinceNow < -5")
            return
        }
        
        if newLocation.horizontalAccuracy < 0{
            print("*** didUpdateLocations: horizontalAccuracy < 0")
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = mLocation {
            distance = newLocation.distance(from: location)
        }
        
        if mLocation == nil || mLocation!.horizontalAccuracy > newLocation.horizontalAccuracy {
            
            mLastLocationError = nil
            mLocation = newLocation
            updateLabels()
        
            if newLocation.horizontalAccuracy <= mLocationManager.desiredAccuracy {
                print("*** We are done!")
                stopLocationManager()
                configureGetButton()
                
                if distance > 0 {
                    mPerformingReverseGeocoding = false
                }
            }
            
            if !mPerformingReverseGeocoding {
                print("*** Goding to geocode");
                
                mPerformingReverseGeocoding = true
                
                mGeoCoder.reverseGeocodeLocation(newLocation, completionHandler: {
                    placemarks, error in
                    
                    print("*** Found placemarks: \(placemarks), error: \(error) ")
                    
                    self.mLastGeocodingError = error;
                    
                    if error == nil, let p = placemarks, !p.isEmpty {
                        self.mPlacemark = p.last!
                    } else {
                        self.mPlacemark = nil
                    }
                    
                    self.mPerformingReverseGeocoding = false
                    self.updateLabels()
                })
            }
            
        } else if distance < 1 {
            let timeInterval = newLocation.timestamp.timeIntervalSince(mLocation!.timestamp)
            
            if timeInterval > 10 {
                print("*** Force done!");
                
                stopLocationManager()
                updateLabels()
                configureGetButton()
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        updateLabels()
        configureGetButton()
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
            
            if let placemark = mPlacemark {
                addressLabel.text = string(from: placemark)
            } else if mPerformingReverseGeocoding {
                addressLabel.text = "Searching for Address..."
            } else if mLastGeocodingError != nil {
                addressLabel.text = "Error Finding Address"
            } else {
                addressLabel.text = "No Address Found"
            }
            
        } else {
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
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
    
    func startLocationManager() {
        if CLLocationManager.locationServicesEnabled() {
            mLocationManager.delegate = self
            mLocationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            mLocationManager.startUpdatingLocation()
            mUpdatingLocation = true
            
            mTimer = Timer.scheduledTimer(timeInterval: 60, target: self, selector: #selector(didTimeOut), userInfo: nil, repeats: false)
        }
    }
    
    func stopLocationManager() {
        if mUpdatingLocation {
            mLocationManager.stopUpdatingLocation()
            mLocationManager.delegate = nil
            mUpdatingLocation = false
            
            if let timer = mTimer {
                timer.invalidate()
            }
        }
    }

    func configureGetButton(){
        if mUpdatingLocation {
            getButton.setTitle("Stop", for: .normal)
        } else {
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
    
    func string(from placemark: CLPlacemark) -> String {
        var line1 = ""
        
        if let s = placemark.subThoroughfare {
            line1 += s + " "
        }
        
        if let s = placemark.thoroughfare {
            line1 += s + " "
        }
        
        var line2 = ""
        
        if let s = placemark.locality {
            line2 += s + " "
        }
        
        if let s = placemark.administrativeArea {
            line2 += s + " "
        }
        
        if let s = placemark.postalCode {
            line2 += s
        }
        
        return line1 + "\n" + line2
    }
    
    func didTimeOut() {
        print("*** Time out")
        
        if mLocation == nil {
            stopLocationManager()
            
            mLastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
}

