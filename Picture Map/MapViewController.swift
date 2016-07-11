//
//  ViewController.swift
//  Picture Map
//
//  Created by Alex King on 7/8/16.
//  Copyright © 2016 Alex King. All rights reserved.
//

import UIKit
import Firebase
import GoogleMaps
import GoogleSignIn

class MapViewController: UIViewController, GIDSignInDelegate, GIDSignInUIDelegate {
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var addButton: UIButton!
    
    var currentUser: GIDGoogleUser?

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        let camera = GMSCameraPosition.cameraWithLatitude(37.0902, longitude: -95.7129, zoom: 3)
        self.mapView.camera = camera
        
        profileImageView.layer.cornerRadius = profileImageView.frame.width/2
        profileImageView.clipsToBounds = true
        
        if (currentUser == nil) {
            GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
            GIDSignIn.sharedInstance().uiDelegate = self
            GIDSignIn.sharedInstance().delegate = self
            GIDSignIn.sharedInstance().signIn()
        }
    }
    
    func signIn(signIn: GIDSignIn!, didSignInForUser user: GIDGoogleUser!, withError error: NSError?) {        
        self.currentUser = user
        self.profileImageView.downloadImageFrom(user.profile.imageURLWithDimension(UInt(self.profileImageView.frame.width)).absoluteString)
    }

    @IBAction func addButtonTapped(sender: AnyObject) {
        let addNavigation = UINavigationController(rootViewController: AddViewController())
        self.presentViewController(addNavigation, animated: true, completion: nil)
    }
}

