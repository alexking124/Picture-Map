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

class MapViewController: UIViewController {
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var addButton: UIButton!
    
    private var locationManager: CLLocationManager?
    private var remainingPhotos: NSInteger?
    fileprivate var lastTappedMarker: GMSMarker?
    
    private var childAddedObserverHandle: UInt = 0
    private var childRemovedObserverHandle: UInt = 0
    private var childChangedObserverHandle: UInt = 0
    
    private var markers = Set<GMSMarker>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.camera(withLatitude: 37.0902, longitude: -95.7129, zoom: 2)
        self.mapView.camera = camera
        self.mapView.isMyLocationEnabled = true
        self.mapView.delegate = self
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        remainingPhotos = -1
        
        FIRAuth.auth()?.addStateDidChangeListener({ (auth, user) in
            if user != nil {
                self.registerForPinUpdates()
                self.checkUsage()
                self.addButton.isEnabled = true
            } else {
                self.childAddedObserverHandle = 0
                self.childChangedObserverHandle = 0
                self.childRemovedObserverHandle = 0
                self.mapView.clear()
                self.addButton.isEnabled = false
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .notDetermined {
            locationManager!.requestWhenInUseAuthorization()
        }
    }
    
    @IBAction func settingsButtonTapped(_ sender: AnyObject) {
        let settingsNavigation = UINavigationController(rootViewController: SettingsViewController())
        self.present(settingsNavigation, animated: true, completion: nil)
    }
    
    @IBAction func addButtonTapped(_ sender: AnyObject) {
        if (self.remainingPhotos! > 0) {
            let addNavigation = UINavigationController(rootViewController: AddViewController())
            self.present(addNavigation, animated: true, completion: nil)
        }
        if (self.remainingPhotos == 0) {
            self.presentUsageWarning()
        }
    }
    
    private func registerForPinUpdates() {
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            return;
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let userReference = databaseReference.child("pins").child(currentUser.uid)
        if childAddedObserverHandle == 0 {
            childAddedObserverHandle = userReference.observe(.childAdded, with: { (snapshot) in
                self.addPinFromSnapshot(snapshot: snapshot)
            })
        }
        
        if childChangedObserverHandle == 0 {
            childChangedObserverHandle = userReference.observe(.childChanged, with: { (newSnapshot) in
                let identifier = newSnapshot.key
                for mapMarker in self.markers {
                    if let userData = mapMarker.userData as? Pin {
                        if identifier == userData.identifier {
                            let snapshotValue = newSnapshot.value as! [String:Any]
                            let latitude = snapshotValue["latitude"] as! CLLocationDegrees
                            let longitude = snapshotValue["longitude"] as! CLLocationDegrees
                            mapMarker.position = CLLocationCoordinate2DMake(latitude, longitude)
                            break
                        }
                    }
                }
            })
        }
        
        if childRemovedObserverHandle == 0 {
            childRemovedObserverHandle = userReference.observe(.childRemoved, with: { (snapshot) in
                let identifier = snapshot.key
                for mapMarker in self.markers {
                    if let userData = mapMarker.userData as? Pin {
                        if identifier == userData.identifier {
                            mapMarker.map = nil
                            self.markers.remove(mapMarker)
                            break
                        }
                    }
                }
            })
        }
    }
    
    private func addPinFromSnapshot(snapshot: FIRDataSnapshot) {
        let pin = Pin(snapshot: snapshot)
        let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
        marker.groundAnchor = CGPoint(x: 0.5,y: 0.5)
        marker.map = self.mapView
        marker.userData = pin
        markers.insert(marker)
        
        let markerView = UIImageView(image: UIImage(named: "empty_image"))
        ImageLoader.sharedLoader.imageForPin(pin: pin, completion: { (image) in
            markerView.image = image
        })
        markerView.contentMode = .scaleAspectFill
        markerView.layer.cornerRadius = 5
        markerView.clipsToBounds = true
        marker.iconView = markerView
    }
    
    private func checkUsage() {
        guard let currentUser = FIRAuth.auth()?.currentUser else {
            return;
        }
        
        let databaseReference = FIRDatabase.database().reference()
        let usageReference = databaseReference.child("limit").child(currentUser.uid)
        usageReference.observe(.value, with: { (snapshot) in
            guard snapshot.exists() else {
                usageReference.setValue(20)
                return
            }
            guard let value = snapshot.value else {
                return
            }
            self.remainingPhotos = (value as AnyObject).integerValue
            if ((value as AnyObject).integerValue == 0) {
                self.presentUsageWarning()
            }
        })
    }
    
    private func presentUsageWarning() {
        let alertController = UIAlertController(title: "You've uploaded your last photo!", message: "Please purchase more photos to continue adding to your Photo Map!", preferredStyle: .alert)
        let defaultAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
        })
        alertController.addAction(defaultAction)
        self.present(alertController, animated: true, completion: nil)
    }
    
}

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.authorizedWhenInUse {
            manager.startUpdatingLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last else {
            return
        }
        let cameraUpdate = GMSCameraUpdate.setTarget(newLocation.coordinate, zoom: 6.0)
        mapView.animate(with: cameraUpdate)
        manager.stopUpdatingLocation()
    }
    
}

extension MapViewController: GMSMapViewDelegate {
    
    func mapView(_ mapView: GMSMapView, didTap marker: GMSMarker) -> Bool {
        let pin = marker.userData as! Pin
        self.lastTappedMarker = marker
        self.present(PhotoViewController(pin: pin), animated: true, completion: nil)
        return true
    }
    
}

