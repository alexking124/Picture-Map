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

class MapViewController: UIViewController, CLLocationManagerDelegate, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var addButton: UIButton!
    
    var currentUser: GIDGoogleUser?
    var locationManager: CLLocationManager?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 3)
        self.mapView.camera = camera
        mapView.myLocationEnabled = true
        mapView.settings.myLocationButton = true
        
        profileButton.layer.cornerRadius = profileButton.frame.width/2
        profileButton.clipsToBounds = true
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        addButton.enabled = false
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if CLLocationManager.authorizationStatus() == .NotDetermined {
            locationManager!.requestWhenInUseAuthorization()
        }
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError?) {
        if let user = user {
            self.currentUser = user
            NSURLSession.sharedSession().dataTaskWithURL(user.profile.imageURLWithDimension(UInt(self.profileButton.frame.width))) { (data, response, error) in
                guard
                    let httpURLResponse = response as? NSHTTPURLResponse where httpURLResponse.statusCode == 200,
                    let mimeType = response?.MIMEType where mimeType.hasPrefix("image"),
                    let data = data where error == nil,
                    let image = UIImage(data: data)
                    else { return }
                dispatch_async(dispatch_get_main_queue(), {
                    self.profileButton.setBackgroundImage(image, forState: .Normal)
                })
            }.resume()
            
            let authentication = user.authentication
            let credential = FIRGoogleAuthProvider.credentialWithIDToken(authentication.idToken, accessToken: authentication.accessToken)
            FIRAuth.auth()?.signInWithCredential(credential) { (user, error) in
                self.addButton.enabled = true
            }
        }
    }

    @IBAction func profileButtonTapped(sender: AnyObject) {
        if (currentUser == nil) {
            GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    @IBAction func addButtonTapped(sender: AnyObject) {
        let addNavigation = UINavigationController(rootViewController: AddViewController())
        self.presentViewController(addNavigation, animated: true, completion: nil)
    }
    
    private func updatePins() {
        let databaseReference = FIRDatabase.database().reference()
    }
}

