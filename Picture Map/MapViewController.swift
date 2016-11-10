//
//  ViewController.swift
//  Picture Map
//
//  Created by Alex King on 7/8/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit
import CoreLocation

import Firebase
import FirebaseAuth
import FirebaseDatabase
import GoogleMaps
import GoogleSignIn

class MapViewController: UIViewController {
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var addButton: UIButton!
    
    var locationManager: CLLocationManager?
    var remainingPhotos: NSInteger?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 2)
        self.mapView.camera = camera
        self.mapView.myLocationEnabled = true
        self.mapView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        remainingPhotos = -1
        
        FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.updatePins()
                self.checkUsage()
                self.addButton.enabled = true
            } else {
                self.mapView.clear()
                self.addButton.enabled = false
            }
        })
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager!.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func settingsButtonTapped(sender: AnyObject) {
        let settingsNavigation = UINavigationController(rootViewController: SettingsViewController())
        self.presentViewController(settingsNavigation, animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(sender: AnyObject) {
        if (self.remainingPhotos > 0) {
            let addNavigation = UINavigationController(rootViewController: AddViewController())
            self.presentViewController(addNavigation, animated: true, completion: nil)
        }
        if (self.remainingPhotos == 0) {
            self.presentUsageWarning()
        }
    }
    
    private func updatePins() {
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            return;
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let userReference = databaseReference.child("pins").child(currentUser.uid)
        userReference.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            let pin = Pin(snapshot: snapshot)
            let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
            marker.groundAnchor = CGPointMake(0.5, 0.5)
            marker.map = self.mapView
            marker.userData = pin
            
            let markerView = UIImageView(image: UIImage(named: "empty_image"))
            ImageLoader.sharedLoader.imageForPin(pin, completion: { (image) in
                markerView.image = image
            })
            markerView.contentMode = .ScaleAspectFill
            markerView.layer.cornerRadius = 5
            markerView.clipsToBounds = true
            marker.iconView = markerView
        })
    }
    
    private func checkUsage() {
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            return;
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let usageReference = databaseReference.child("limit").child(currentUser.uid)
        usageReference.observeEventType(.Value, withBlock: { (snapshot) in
            guard snapshot.exists() else {
                usageReference.setValue(10)
                return
            }
            guard let value = snapshot.value else {
                return
            }
            self.remainingPhotos = value.integerValue
            if (value.integerValue == 0) {
                self.presentUsageWarning()
            }
        })
    }
    
    private func presentUsageWarning() {
        let alertController = UIAlertController(title: "You've uploaded your last photo!", message: "Please purchase more photos to continue adding to your Photo Map!", preferredStyle: .Alert)
        let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: { (action) in
        })
        alertController.addAction(defaultAction)
        self.presentViewController(alertController, animated: true, completion: nil)
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            locationManager?.startUpdatingLocation()
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        let cameraUpdate = GMSCameraUpdate.setTarget(newLocation.coordinate, zoom: 6.0)
        mapView.animateWithCameraUpdate(cameraUpdate)
        manager.stopUpdatingLocation()
    }
    
}

extension MapViewController: GMSMapViewDelegate {
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        let pin = marker.userData as! Pin
        self.presentViewController(PhotoViewController(pin: pin), animated: true, completion: nil)
        return true
    }
    
}

