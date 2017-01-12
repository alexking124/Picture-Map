//
//  LocationPickerViewController.swift
//  Picture Map
//
//  Created by Alex King on 1/11/17.
//  Copyright © 2017 Alex King. All rights reserved.
//

import CoreLocation
import GoogleMaps
import UIKit

protocol LocationPickerDelegate: class {
    func didFinishPickingLocation(location: CLLocationCoordinate2D)
}

class LocationPickerViewController: UIViewController {
    
    @IBOutlet weak var mapView: GMSMapView!
    @IBOutlet weak var useDefaultButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    @IBOutlet weak var pinImageView: UIImageView!
    
    var defaultLocation: CLLocationCoordinate2D?
    weak var delegate: LocationPickerDelegate?
    
    init(_ defaultLocation: CLLocationCoordinate2D?) {
        super.init(nibName: "LocationPickerViewController", bundle: nil)
        self.defaultLocation = defaultLocation
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if defaultLocation == nil {
            useDefaultButton.isHidden = true
        }
        
        mapView.bringSubview(toFront: useDefaultButton)
        mapView.bringSubview(toFront: doneButton)
        mapView.bringSubview(toFront: pinImageView)
        
        doneButton.layer.cornerRadius = 4
        useDefaultButton.layer.cornerRadius = 4
        
        mapView.isMyLocationEnabled = true
        mapView.settings.tiltGestures = false
        mapView.settings.rotateGestures = false
        mapView.settings.myLocationButton = true
        
        moveMapToDefaultLocation()
        
    }
    
    func moveMapToDefaultLocation() {
        let userLocation = mapView.myLocation
        let startLocation = (defaultLocation ?? userLocation?.coordinate)
        if let startLocation = startLocation {
            let cameraUpdate = GMSCameraUpdate.setTarget(startLocation, zoom: 10.0)
            mapView.animate(with: cameraUpdate)
        } else { // Fallback if all else fails
            let cameraUpdate = GMSCameraUpdate.setTarget(CLLocationCoordinate2DMake(37.0902, -95.7129), zoom: 2.0)
            mapView.animate(with: cameraUpdate)
        }
    }
    
    @IBAction func useDefaultButtonPressed(_ sender: Any) {
        moveMapToDefaultLocation()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        if let delegate = delegate {
            delegate.didFinishPickingLocation(location: mapView.camera.target)
        }
    }
    
}

