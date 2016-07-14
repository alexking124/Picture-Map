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

class MapViewController: UIViewController, CLLocationManagerDelegate, GIDSignInDelegate, GIDSignInUIDelegate, GMSMapViewDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var addButton: UIButton!
    
    var locationManager: CLLocationManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 2)
        self.mapView.camera = camera
        self.mapView.myLocationEnabled = true
        self.mapView.delegate = self
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        if (FIRAuth.auth()?.currentUser == nil) {
            addButton.enabled = false
            GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().signIn()
        } else {
            self.profileImageView.downloadImageFrom((FIRAuth.auth()?.currentUser?.photoURL)!.absoluteString)
            self.updatePins()
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager!.requestWhenInUseAuthorization()
        }
    }
    
    func mapView(mapView: GMSMapView, didTapMarker marker: GMSMarker) -> Bool {
        let pin = marker.userData as! Pin
        self.presentViewController(PhotoViewController(pin: pin), animated: true, completion: nil)
        return true
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser googleUser: GIDGoogleUser!, withError error: NSError?) {
        if let googleUser = googleUser {
            let authentication = googleUser.authentication
            let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                if error != nil {
                    return
                }
                
                let updateProperty = user?.profileChangeRequest()
                updateProperty?.photoURL = googleUser.profile.imageURLWithDimension(UInt(self.profileImageView.frame.width))
                updateProperty?.commitChangesWithCompletion(nil)
                self.profileImageView.downloadImageFrom((FIRAuth.auth()?.currentUser?.photoURL)!.absoluteString)
                self.addButton.enabled = true
                self.updatePins()
            }
        }
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
        userReference.observeSingleEventOfType(.Value, withBlock: { pinsSnapshot in
            if pinsSnapshot.value is NSNull {
                print("No pins found")
                return
            }
            for pin in Pin.parseFromSnapshot(pinsSnapshot) {
                let marker = GMSMarker(position: CLLocationCoordinate2D(latitude: pin.latitude, longitude: pin.longitude))
                marker.map = self.mapView
                marker.userData = pin
            }
        })
        
        userReference.observeEventType(.ChildAdded, withBlock: { (snapshot) in
            print(snapshot.key)
        })
    }
    
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

