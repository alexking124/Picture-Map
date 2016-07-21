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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 2)
        self.mapView.camera = camera
        self.mapView.myLocationEnabled = true
        self.mapView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        FIRAuth.auth()?.addAuthStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.updatePins()
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
        let addNavigation = UINavigationController(rootViewController: AddViewController())
        self.presentViewController(addNavigation, animated: true, completion: nil)
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

